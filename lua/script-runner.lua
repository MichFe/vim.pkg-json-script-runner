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

-- Telescope integration
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function run_npm_script(script)
  print("Running script: " .. script)
  -- Opens a terminal and runs the script
  vim.cmd("vsplit | terminal npm run " .. script)
end

local function telescope_package_scripts()
  local scripts = get_json_scripts()

  pickers.new({}, {
    prompt_title = "NPM Scripts",
    finder = finders.new_table {
      results = scripts,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      local run_script = function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        run_npm_script(selection[1])
      end

      map("i", "<CR>", run_script)
      map("n", "<CR>", run_script)

      return true
    end,
  }):find()
end

print("Json runner loaded")
return M
