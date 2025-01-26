-- tests/minimal_init.lua

local PLUGINS = {
	PLENARY = {
		name = "plenary.nvim",
		repo = "https://github.com/nvim-lua/plenary.nvim",
	},
}

-- Using pack/vendor/start ensures proper plugin loading in Neovim's startup sequence
local INSTALL_DIR = {
	base = vim.fn.stdpath("data") .. "/site/pack/vendor/start",
	cleanup = {
		vim.fn.stdpath("data") .. "/site",
		vim.fn.stdpath("data") .. "/pack",
		vim.fn.stdpath("config"),
	},
}

---@param plugin table Plugin definition containing name and repo
---@return string install_path The path where the plugin is installed
local function ensure_plugin(plugin)
	local install_path = INSTALL_DIR.base .. "/" .. plugin.name
	vim.fn.mkdir(vim.fn.fnamemodify(install_path, ":h"), "p")

	if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
		print(string.format("Installing %s...", plugin.name))

		local clone_cmd = string.format("git clone --depth 1 %s %s", plugin.repo, install_path)
		local result = vim.fn.system(clone_cmd)

		if vim.v.shell_error ~= 0 then
			error(string.format("Failed to install %s:\n%s", plugin.name, result))
		end

		print(string.format("Successfully installed %s", plugin.name))
	end

	vim.opt.rtp:prepend(install_path)
	local after_dir = install_path .. "/after"
	if vim.fn.isdirectory(after_dir) == 1 then
		vim.opt.rtp:append(after_dir)
	end

	return install_path
end

local plugin_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h")
vim.opt.rtp:prepend(plugin_root)

for _, path in ipairs(INSTALL_DIR.cleanup) do
	vim.opt.rtp:remove(path)
	print(string.format("Successfully cleaned %s", path))
end

ensure_plugin(PLUGINS.PLENARY)

-- Verify Plenary loads correctly before proceeding
local ok, plenary_test = pcall(require, "plenary.test_harness")
if not ok then
	error("Failed to load Plenary's test harness. Make sure it's installed correctly.")
end

-- Disable file writing since we don't need it for tests
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
vim.o.undofile = false
vim.opt.shortmess:append("A")

return {
	test_harness = plenary_test,
	ensure_plugin = ensure_plugin,
}
