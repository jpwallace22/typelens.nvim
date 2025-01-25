local ts = require("typelens.typescript")

---@class CommandsModule
local M = {}

---Setup all of the commands
function M.setup()
	vim.api.nvim_create_user_command("TypeLens", function()
		ts.check_types()
	end, {
		desc = "Run TypeScript type checking",
	})
end

return M
