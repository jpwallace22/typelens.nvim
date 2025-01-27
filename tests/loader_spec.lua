local assert = require("luassert")
local describe = require("plenary.busted").describe
local it = require("plenary.busted").it
local before_each = require("plenary.busted").before_each
local after_each = require("plenary.busted").after_each

local Loader = require("typelens.loader")

local function wait_for_schedule()
	vim.wait(100, function()
		return false
	end)
end

describe("Loader", function()
	local loader

	before_each(function()
		loader = Loader:new()
	end)

	after_each(function()
		if loader then
			loader:stop()
		end
	end)

	describe("new()", function()
		it("creates a loader with default values", function()
			assert.are.same(Loader.frames, loader.frames)
			assert.are.same(Loader.message, loader.message)
			assert.is_nil(loader._win)
			assert.is_nil(loader._buf)
			assert.is_nil(loader._timer)
		end)

		it("creates a loader with custom frames", function()
			local custom_frames = { "1", "2", "3" }
			loader = Loader:new({ frames = custom_frames })
			assert.are.same(custom_frames, loader.frames)
		end)

		it("creates a loader with custom message", function()
			local custom_message = "Custom loading..."
			loader = Loader:new({ message = custom_message })
			assert.are.same(custom_message, loader.message)
		end)
	end)

	describe("start()", function()
		it("creates a valid buffer", function()
			loader:start()
			assert.is_true(vim.api.nvim_buf_is_valid(loader._buf))
			assert.is_true(vim.api.nvim_buf_is_loaded(loader._buf))
		end)

		it("creates a valid window", function()
			loader:start()
			assert.is_true(vim.api.nvim_win_is_valid(loader._win))
		end)

		it("sets correct window options", function()
			loader:start()
			assert.equals(0, vim.wo[loader._win].winblend)
			assert.equals("Normal:None", vim.wo[loader._win].winhighlight)
		end)

		it("creates and starts a timer", function()
			loader:start()
			assert.is_not_nil(loader._timer)
			-- Can't directly test timer functionality in sync code
		end)

		it("sets initial text correctly", function()
			loader:start()
			local lines = vim.api.nvim_buf_get_lines(loader._buf, 0, -1, false)
			assert.are.same({ loader.frames[1] .. " " .. loader.message }, lines)
		end)
	end)

	describe("stop()", function()
		before_each(function()
			loader:start()
		end)

		it("stops and cleans up timer", function()
			local timer = loader._timer
			loader:stop()
			assert.is_nil(loader._timer)
		end)

		it("closes window", function()
			local win = loader._win
			loader:stop()
			wait_for_schedule()
			assert.is_nil(loader._win)
			assert.is_false(vim.api.nvim_win_is_valid(win))
		end)

		it("deletes buffer", function()
			local buf = loader._buf
			loader:stop()
			wait_for_schedule()
			assert.is_nil(loader._buf)
			assert.is_false(vim.api.nvim_buf_is_valid(buf))
		end)

		it("handles multiple stop calls gracefully", function()
			loader:stop()
			assert.has_no.errors(function()
				loader:stop()
			end)
		end)
	end)

	describe("edge cases", function()
		it("handles empty frames array", function()
			loader = Loader:new({ frames = {} })
			assert.has_no.errors(function()
				loader:start()
			end)
		end)

		it("handles empty message", function()
			loader = Loader:new({ message = "" })
			assert.has_no.errors(function()
				loader:start()
			end)
		end)

		it("handles window close before stop", function()
			loader:start()
			vim.api.nvim_win_close(loader._win, true)
			assert.has_no.errors(function()
				loader:stop()
			end)
		end)

		it("handles buffer delete before stop", function()
			loader:start()
			vim.api.nvim_buf_delete(loader._buf, { force = true })
			assert.has_no.errors(function()
				loader:stop()
			end)
		end)
	end)
end)
