-- Register commands and health checks
if vim.fn.has("nvim-0.8.0") == 1 then
	-- Register the main command
	vim.api.nvim_create_autocmd("User", {
		pattern = "LazyLoad",
		callback = function(event)
			if event.data == "typelens" then
				vim.api.nvim_create_user_command("TypeLens", function()
					require("typelens.typescript").check_types()
				end, {
					desc = "Run TypeScript type checking",
				})
			end
		end,
	})

	-- Register health check
	vim.api.nvim_create_user_command("TypeLensHealth", function()
		require("typelens.health").check()
	end, {
		desc = "Run TypeLens health checks",
	})
end
