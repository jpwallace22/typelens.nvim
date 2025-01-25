---@alias DisplayOutput "trouble"|"quickfix"

---@class TypeLensConfig
---@field display_output? DisplayOutput Display output type, either "trouble" or "quickfix"
---@field typescript_path? string Path to TypeScript compiler
---@field auto_open? boolean Automatically open quickfix window
---@field keys? {check_types: string} Optional key mappings

---@class TypeLensConfigModule
local M = {}

---Default configuration values
---@type TypeLensConfig
M.values = {
	display_output = "trouble",
	typescript_path = "npx tsc",
	auto_open = true,
	keys = {
		check_types = "<leader>ck",
	},
}

---Validate configuration values
---@param config TypeLensConfig Configuration to validate
---@return boolean success Whether the configuration is valid
---@return string? error_message Error message if validation failed
function M.validate_config(config)
	if type(config) ~= "table" then
		return false, "Config must be a table"
	end

	-- Validate display_output
	if config.display_output ~= nil then
		if type(config.display_output) ~= "string" then
			return false, "display_output must be a string"
		end
		if config.display_output ~= "trouble" and config.display_output ~= "quickfix" then
			return false, 'display_output must be either "trouble" or "quickfix"'
		end
	end

	-- Validate typescript_path
	if config.typescript_path ~= nil then
		if type(config.typescript_path) ~= "string" then
			return false, "typescript_path must be a string"
		end
		if config.typescript_path:gsub("%s", "") == "" then
			return false, "typescript_path cannot be empty"
		end
	end

	-- Validate auto_open
	if config.auto_open ~= nil and type(config.auto_open) ~= "boolean" then
		return false, "auto_open must be a boolean"
	end

	if config.keys ~= nil then
		if type(config.keys) ~= "table" then
			return false, "keys must be a table"
		end
		if config.keys.check_types ~= nil and type(config.keys.check_types) ~= "string" then
			return false, "keys.check_types must be a string"
		end
	end

	return true
end

---Setup configuration
---@param opts TypeLensConfig? Optional configuration override
function M.setup(opts)
	if opts then
		local success, error_message = M.validate_config(opts)
		if not success then
			error("[TypeLens] " .. error_message)
		end
	end
	M.values = vim.tbl_deep_extend("force", M.values, opts or {})
end

---@type fun(opts: TypeLensConfig?)
M.apply = M.setup

return M
