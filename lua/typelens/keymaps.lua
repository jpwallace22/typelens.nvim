---@class KeymapsModule
local M = {}

---@param values TypeLensConfig
function M.setup(values)
	local keys = values.keys
	if keys and keys.check_types then
		vim.keymap.set("n", keys.check_types, "<cmd>TypeLens<cr>", { desc = "TypeLens: Check types" })
	end
end

return M
