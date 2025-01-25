local config = require("typelens.config")
local commands = require("typelens.commands")
local typescript = require("typelens.typescript")
local keymaps = require("typelens.keymaps")

---@class Typelens
local M = {}

function M.setup(opts)
	config.setup(opts)
	commands.setup()
	keymaps.setup(config.values)
end

function M.examine_types()
	typescript.check_types()
end

return M
