vim.api.nvim_create_user_command("NpmScripts", function()
  require("script-runner").telescope_package_scripts()
end, { desc = "Run npm scripts from package.json" })
