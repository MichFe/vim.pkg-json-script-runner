local M = {}

M.setup = function()
end

local get_json_scripts = function()
  local package_json_path = vim.fn.getcwd() .. '/package.json'
  -- Comment out or remove debug prints when stable
  -- print(package_json_path)

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

  -- print(vim.inspect(scripts))
  return scripts
end

-- State to track running job and buffer
local job_id = nil
local bufnr = nil

local function stop_npm_script()
  if job_id then
    vim.fn.jobstop(job_id)
    job_id = nil
  end
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    bufnr = nil
  end
end

local function run_npm_script(script)
  -- Stop old job and buffer first
  stop_npm_script()

  -- Create a new buffer for terminal
  bufnr = vim.api.nvim_create_buf(false, true)

  -- Open a floating window (adjust size/position as you want)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Start terminal job inside buffer
  job_id = vim.fn.termopen("npm run " .. script, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        vim.notify("npm script exited with code: " .. code, vim.log.levels.INFO)
        job_id = nil
        -- Optionally close the buffer/window automatically:
        -- if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        --   vim.api.nvim_buf_delete(bufnr, { force = true })
        --   bufnr = nil
        -- end
      end)
    end,
  })
end

-- Telescope integration
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

function M.telescope_package_scripts()
  local scripts = get_json_scripts()
  if #scripts == 0 then
    vim.notify("No scripts found in package.json", vim.log.levels.WARN)
    return
  end

  pickers.new({}, {
    prompt_title = "NPM Scripts",
    finder = finders.new_table {
      results = scripts,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      local run_script = function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection or not selection[1] then
          vim.notify("No script selected", vim.log.levels.WARN)
          return
        end
        actions.close(prompt_bufnr)
        run_npm_script(selection[1])
      end

      map("i", "<CR>", run_script)
      map("n", "<CR>", run_script)

      return true
    end,
  }):find()
end

-- Optionally expose stop function for manual stopping
M.stop_npm_script = stop_npm_script

print("Json runner loaded")
return M

