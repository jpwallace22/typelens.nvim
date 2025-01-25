local M = {}

local health = vim.health or require("health")

local function check_typescript()
	if vim.fn.executable("npx") ~= 1 then
		health.error("npx is not installed. Please install Node.js and npm")
		return
	end

	-- Check if we can run tsc
	local handle = io.popen("npx tsc --version 2>&1")
	if not handle then
		health.error("Could not execute TypeScript compiler")
		return
	end

	local result = handle:read("*a")
	handle:close()

	if result:match("Version %d+%.%d+%.%d+") then
		health.ok("TypeScript compiler found: " .. result:gsub("^%s*(.-)%s*$", "%1"))
	else
		health.error("TypeScript is not installed. Run: npm install -g typescript")
	end
end

local function check_dependencies()
	local has_trouble = pcall(require, "trouble")
	if has_trouble then
		health.ok("trouble.nvim is installed")
	else
		health.warn("trouble.nvim is not installed (optional but recommended)")
	end
end

local function check_config()
	local config = require("typelens.config")
	local values = config.values

	health.info(vim.inspect(config.values))
	if not values then
		health.error("Configuration not loaded properly")
		return
	end
	local success
	local error_message

	if values then
		success, error_message = config.validate_config(values)
		if not success then
			health.warn(string.format("Invalid configuration", error_message))
		end
	end
	if success then
		health.ok("Config is valid")
	end
end

function M.check()
	health.start("TypeLens")

	health.info("Checking TypeScript installation...")
	check_typescript()

	health.info("Checking dependencies...")
	check_dependencies()

	health.info("Checking configuration...")
	check_config()
end

return M
