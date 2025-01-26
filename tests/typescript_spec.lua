local assert = require("luassert")
local describe = require("plenary.busted").describe
local it = require("plenary.busted").it
local before_each = require("plenary.busted").before_each
local after_each = require("plenary.busted").after_each

local typescript = require("typelens.typescript")

local function setup_vim_mocks()
	local original = {
		schedule = vim.schedule,
		setqflist = vim.fn.setqflist,
		require = require,
		cmd = vim.cmd,
	}

	local spy = {
		schedule_called = false,
		setqflist_called = false,
		trouble_opened = false,
		quickfix_opened = false,
		last_qf_items = nil,
	}

	-- Set up mock functions
	vim.schedule = function(cb)
		spy.schedule_called = true
		cb()
	end

	vim.fn.setqflist = function(items)
		spy.setqflist_called = true
		spy.last_qf_items = items
	end

	vim.cmd = function(cmd)
		if cmd == "copen" then
			spy.quickfix_opened = true
		end
	end

	local mock_trouble = {
		open = function()
			spy.trouble_opened = true
		end,
	}

	_G.require = function(module)
		if module == "trouble" then
			return mock_trouble
		end
		return original.require(module)
	end

	return original, spy
end

local function restore_vim_functions(original)
	vim.schedule = original.schedule
	vim.fn.setqflist = original.setqflist
	_G.require = original.require
	vim.cmd = original.cmd
end

describe("typescript module", function()
	describe("parse_error_line", function()
		it("should parse a basic TypeScript error line", function()
			local line = "src/components/App.tsx(123,45): Type 'string' is not assignable to type 'number'."
			local result = typescript.parse_error_line(line)

			assert.same({
				filename = "src/components/App.tsx",
				lnum = 123,
				col = 45,
				text = "Type 'string' is not assignable to type 'number'.",
				type = "E",
			}, result)
		end)

		it("should handle Windows-style file paths", function()
			local line = "C:\\project\\src\\App.tsx(10,15): Cannot find name 'React'."
			local result = typescript.parse_error_line(line)

			assert.same({
				filename = "C:\\project\\src\\App.tsx",
				lnum = 10,
				col = 15,
				text = "Cannot find name 'React'.",
				type = "E",
			}, result)
		end)

		it("should handle paths with parentheses", function()
			local line = "src/(test)/App.tsx(10,15): Type error."
			local result = typescript.parse_error_line(line)

			assert.same({
				filename = "src/(test)/App.tsx",
				lnum = 10,
				col = 15,
				text = "Type error.",
				type = "E",
			}, result)
		end)

		it("should return nil for non-error lines", function()
			local invalid_lines = {
				"Starting compilation...",
				"Found 3 errors.",
				"",
				"    at Object.<anonymous> (/path/to/file.js:10:5)",
				"1 error",
			}

			for _, line in ipairs(invalid_lines) do
				local result = typescript.parse_error_line(line)
				assert.is_nil(result, "Should return nil for: " .. line)
			end
		end)
	end)

	describe("handle_compiler_output", function()
		it("should process a new error line", function()
			local findings = {}
			local current_error = nil
			local line = "src/utils.ts(10,5): Cannot find name 'someVar'."

			local new_findings, new_current_error = typescript.handle_compiler_output(findings, current_error, line)

			assert.same({}, new_findings)
			assert.same({
				filename = "src/utils.ts",
				lnum = 10,
				col = 5,
				text = "Cannot find name 'someVar'.",
				type = "E",
			}, new_current_error)
		end)

		it("should handle multi-line error messages", function()
			local findings = {}
			local current_error = {
				filename = "src/utils.ts",
				lnum = 10,
				col = 5,
				text = "Type '{ name: string; }' is not assignable to type 'User'.",
				type = "E",
			}
			local line = "    Property 'id' is missing in type '{ name: string; }'."

			local new_findings, new_current_error = typescript.handle_compiler_output(findings, current_error, line)

			assert.same({}, new_findings)
			assert.same({
				filename = "src/utils.ts",
				lnum = 10,
				col = 5,
				text = "Type '{ name: string; }' is not assignable to type 'User'.\n  Property 'id' is missing in type '{ name: string; }'.",
				type = "E",
			}, new_current_error)
		end)

		it("should handle consecutive errors", function()
			local findings = {}
			local current_error = {
				filename = "src/first.ts",
				lnum = 1,
				col = 1,
				text = "First error",
				type = "E",
			}
			local line = "src/second.ts(2,2): Second error"

			local new_findings, new_current_error = typescript.handle_compiler_output(findings, current_error, line)

			assert.same({
				{
					filename = "src/first.ts",
					lnum = 1,
					col = 1,
					text = "First error",
					type = "E",
				},
			}, new_findings)

			assert.same({
				filename = "src/second.ts",
				lnum = 2,
				col = 2,
				text = "Second error",
				type = "E",
			}, new_current_error)
		end)
	end)

	describe("display_findings", function()
		local original, spy

		before_each(function()
			original, spy = setup_vim_mocks()
		end)

		after_each(function()
			restore_vim_functions(original)
		end)

		it("should display findings in trouble when configured", function()
			local findings = {
				{
					filename = "test.ts",
					lnum = 1,
					col = 1,
					text = "Test error",
					type = "E",
				},
			}
			local config = {
				display_output = "trouble",
				auto_open = true,
			}

			typescript.display_findings(findings, config)

			assert.truthy(spy.schedule_called)
			assert.truthy(spy.setqflist_called)
			assert.truthy(spy.trouble_opened)
			assert.same(findings, spy.last_qf_items)
		end)

		it("should display findings in quickfix when trouble is not configured", function()
			local findings = {
				{
					filename = "test.ts",
					lnum = 1,
					col = 1,
					text = "Test error",
					type = "E",
				},
			}
			local config = {
				display_output = "quickfix",
				auto_open = true,
			}

			typescript.display_findings(findings, config)

			assert.truthy(spy.schedule_called)
			assert.truthy(spy.setqflist_called)
			assert.truthy(spy.quickfix_opened)
			assert.same(findings, spy.last_qf_items)
		end)

		it("should not open any window when auto_open is false", function()
			local findings = {
				{
					filename = "test.ts",
					lnum = 1,
					col = 1,
					text = "Test error",
					type = "E",
				},
			}
			local config = {
				display_output = "quickfix",
				auto_open = false,
			}

			typescript.display_findings(findings, config)

			assert.truthy(spy.schedule_called)
			assert.truthy(spy.setqflist_called)
			assert.falsy(spy.quickfix_opened)
			assert.falsy(spy.trouble_opened)
		end)

		it("should not open windows when there are no findings", function()
			local findings = {}
			local config = {
				display_output = "trouble",
				auto_open = true,
			}

			typescript.display_findings(findings, config)

			assert.truthy(spy.schedule_called)
			assert.truthy(spy.setqflist_called)
			assert.falsy(spy.trouble_opened)
			assert.falsy(spy.quickfix_opened)
		end)
	end)

	describe("check_types", function()
		local original
		local original_system = vim.system
		local system_called = false
		local system_args = nil

		before_each(function()
			original, _ = setup_vim_mocks()
			vim.system = function(cmd, opts, callback)
				system_called = true
				system_args = { cmd = cmd, opts = opts }
				callback()
			end
		end)

		after_each(function()
			restore_vim_functions(original)
			vim.system = original_system
			system_called = false
			system_args = nil
		end)

		it("should execute TypeScript compiler with correct options", function()
			local mock_config = {
				tsc_command = "tsc --noEmit",
				display_output = "trouble",
				auto_open = true,
			}

			-- Mock the config module
			package.loaded["typelens.config"] = { values = mock_config }

			typescript.check_types()

			assert.truthy(system_called)
			assert.same("tsc --noEmit", system_args.cmd)
			assert.same(vim.fn.getcwd(), system_args.opts.cwd)
			assert.truthy(system_args.opts.text)
		end)
	end)
end)
