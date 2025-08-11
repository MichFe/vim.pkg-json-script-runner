local M = {}

M.setup = function()
end

local get_json_scripts = function()
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  print(package_json_path)

  local file = io.open(package_json_path, "r")
  if not file then
    vim.notify("No package.json found in the current directory", vim.log.levels.WARN)
    return {}
  end

  local file_content = file:read("*a")
  file:close()

  local ok, json = pcall(vim.json.decode, file_content)
  if not ok or not json.scripts then
    vim.notify("No scripts found in package.json", vim.log.levels.ERROR)
    return {}
  end

  local scripts = {}
  for name, _ in pairs(json.scripts) do
    table.insert(scripts, name)
  end
  table.sort(scripts)

  print(vim.inspect(scripts))
  return scripts

end

print("Json runner loaded")
get_json_scripts()

return M
