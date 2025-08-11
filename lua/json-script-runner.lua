local M = {}

M.setup = function()
end

local get_json_scripts = function()
end

local get_json_file = function()
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  print(package_json_path)
end

get_json_file()

return M
