return {
	name = "typelens.nvim",
	version = "0.1.0",
	repository = "jpwallace22/typelens.nvim",
	description = "TypeScript type checking integration for Neovim",
	dependencies = {
		["nvim"] = ">=0.8.0",
		["trouble.nvim"] = ">=0.1.0",
	},
	health = {
		required_executables = {
			"npx",
		},
	},
}
