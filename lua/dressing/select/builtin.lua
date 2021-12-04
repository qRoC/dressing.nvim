local util = require("dressing.util")
local M = {}

M.is_supported = function()
  return true
end

local _callback = function(item, idx) end
local _items = {}
local function clear_callback()
  _callback = function() end
  _items = {}
end

M.select = function(config, items, opts, on_choice)
  _callback = on_choice
  _items = items
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  local lines = {}
  local max_width = 1
  for _, item in ipairs(items) do
    local line = opts.format_item(item)
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  local winopt = {
    relative = config.relative,
    anchor = config.anchor,
    row = config.row,
    col = config.col,
    border = config.border,
    width = util.calculate_width(max_width, config),
    height = util.calculate_height(#lines, config),
    zindex = 150,
    style = "minimal",
  }
  local winnr = vim.api.nvim_open_win(bufnr, true, winopt)
  vim.api.nvim_win_set_option(winnr, "winblend", config.winblend)
  vim.api.nvim_win_set_option(winnr, "cursorline", true)
  pcall(vim.api.nvim_win_set_option, winnr, "cursorlineopt", "both")

  local function map(lhs, rhs)
    vim.api.nvim_buf_set_keymap(bufnr, "n", lhs, rhs, { silent = true, noremap = true })
  end

  map("<CR>", [[<cmd>lua require('dressing.select.builtin').choose()<CR>]])
  map("<C-c>", [[<cmd>lua require('dressing.select.builtin').cancel()<CR>]])
  map("<Esc>", [[<cmd>lua require('dressing.select.builtin').cancel()<CR>]])
  vim.cmd([[
      autocmd BufLeave <buffer> ++nested ++once lua require('dressing.select.builtin').cancel()
  ]])
end

M.choose = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = cursor[1]
  local item = _items[idx]
  local callback = _callback
  clear_callback()
  vim.api.nvim_win_close(0, true)
  callback(item, idx)
end

M.cancel = function()
  local callback = _callback
  clear_callback()
  vim.api.nvim_win_close(0, true)
  callback(nil, nil)
end

return M
