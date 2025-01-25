---@class Finding
---@field file? string File path where the error occurred
---@field line? number Line number of the error
---@field column? number Column number of the error
---@field message string Error message
---@field code? string Error code
---@field severity "error"|"warning" Severity level of the finding

---@class CurrentError
---@field file? string File path where the error occurred
---@field line? number Line number of the error
---@field column? number Column number of the error
---@field message string Error message
---@field code? string Error code
---@field severity? "error"|"warning" Severity level of the finding

---@class UtilsModule
local M = {}

---Create output handler function for typescript compiler
---@param temp_file string Path to temporary file
---@return fun(context: any, data: string?) Handler function that writes compiler output to temporary file
function M.create_output_handler(temp_file)
	return function(_, data)
		if data then
			local file = io.open(temp_file, "a")
			if file then
				file:write(data)
				file:close()
			end
		end
	end
end

---Process temporary file containing typescript compiler output
---@param temp_file string Path to temporary file
---@param handler fun(findings: Finding[], current_error: CurrentError?, line: string): Finding[], CurrentError? Function to handle each line
---@return Finding[] Processed findings
function M.process_temp_file(temp_file, handler)
	local findings = {}
	local current_error = nil
	local file = io.open(temp_file, "r")
	if file then
		for line in file:lines() do
			findings, current_error = handler(findings, current_error, line)
		end
		if current_error then
			table.insert(findings, current_error)
		end
		file:close()
		os.remove(temp_file)
	end
	return findings
end

return M
