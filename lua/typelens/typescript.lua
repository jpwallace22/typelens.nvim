---@class ErrorInfo
---@field filename string File path where the error occurred
---@field lnum number Line number of the error
---@field col number Column number of the error
---@field text string Error message text
---@field type string Error type indicator ('E' for error)

---@class TypeLensModule
---@field check_types fun() Function to run TypeScript type checking

---@class Config
---@field values ConfigValues

---@class ConfigValues
---@field display_output string Where to display output ('trouble' or other)
---@field auto_open boolean Whether to automatically open the output window

local utils = require("typelens.utils")
local loader = require("typelens.loader")

---@class TypescriptModule
local M = {}

---Parse TypeScript error output line
---@param line string Error line from TypeScript compiler
---@return ErrorInfo|nil Parsed error information
function M.parse_error_line(line)
	-- Look for the last set of parentheses containing digits and a comma
	-- This helps us distinguish between parentheses in the path and the line/column parentheses
	local filepath, lnum, col, err_text = line:match("(.-)%((%d+),(%d+)%): (.+)")
	if filepath and lnum and col and err_text then
		return {
			filename = filepath,
			lnum = tonumber(lnum),
			col = tonumber(col),
			text = err_text,
			type = "E",
		}
	end
	return nil
end

---Handle TypeScript compiler output
---@param findings ErrorInfo[] List of findings
---@param current_error ErrorInfo|nil Current error being processed
---@param line string Current line being processed
---@return ErrorInfo[], ErrorInfo|nil Updated findings and current error
function M.handle_compiler_output(findings, current_error, line)
	local error_info = M.parse_error_line(line)
	if error_info then
		if current_error then
			table.insert(findings, current_error)
		end
		return findings, error_info
	elseif current_error and line:match("^%s+") then
		current_error.text = current_error.text .. "\n  " .. line:gsub("^%s+", "")
		return findings, current_error
	end
	return findings, current_error
end

---Display findings in appropriate window
---@param findings ErrorInfo[] List of findings
---@param config TypeLensConfig
function M.display_findings(findings, config)
	vim.schedule(function()
		vim.fn.setqflist(findings)
		if #findings > 0 then
			if config.display_output == "trouble" and pcall(require, "trouble") then
				require("trouble").open({
					mode = "quickfix",
					auto_jump = true,
					focus = true,
				})
			elseif config.auto_open then
				vim.cmd("copen")
			end
		end
	end)
end

---Run TypeScript type checking
function M.check_types()
	loader:start()
	local config = require("typelens.config").values
	local temp_file = vim.fn.tempname()
	local cwd = vim.fn.getcwd()
	vim.system(config.tsc_command, {
		cwd = cwd,
		text = true,
		stdout = utils.create_output_handler(temp_file),
		stderr = utils.create_output_handler(temp_file),
	}, function()
		local findings = utils.process_temp_file(temp_file, M.handle_compiler_output)
		M.display_findings(findings, config)
		loader:stop()
	end)
end

return M
