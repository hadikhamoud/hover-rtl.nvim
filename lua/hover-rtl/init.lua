local M = {}

M.config = {
  enabled = true,
  border = "rounded",
  highlight = "NormalFloat",
}

local function is_arabic_text(text)
  for i = 1, #text do
    local byte = string.byte(text, i)
    if byte >= 0xD8 and byte <= 0xDF then
      return true
    end
  end
  
  return text:match("[\u{0600}-\u{06FF}]") or 
         text:match("[\u{0750}-\u{077F}]") or
         text:match("[\u{08A0}-\u{08FF}]") or
         text:match("[\u{FB50}-\u{FDFF}]") or
         text:match("[\u{FE70}-\u{FEFF}]")
end

local function reverse_text(text)
  local chars = {}
  for char in vim.gsplit(text, "") do
    if char ~= "" then
      table.insert(chars, 1, char)
    end
  end
  return table.concat(chars)
end

local function show_rtl_hover()
  local current_word = vim.fn.expand("<cword>")
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local col = cursor_pos[2]
  
  local word_start = col
  local word_end = col
  
  while word_start > 0 and current_line:sub(word_start, word_start):match("%S") do
    word_start = word_start - 1
  end
  word_start = word_start + 1
  
  while word_end <= #current_line and current_line:sub(word_end + 1, word_end + 1):match("%S") do
    word_end = word_end + 1
  end
  
  local selected_text = current_line:sub(word_start, word_end)
  
  if not selected_text or selected_text == "" then
    return
  end
  
  if is_arabic_text(selected_text) then
    local rtl_text = reverse_text(selected_text)
    
    local opts = {
      relative = "cursor",
      width = #rtl_text + 2,
      height = 1,
      row = 1,
      col = 0,
      style = "minimal",
      border = M.config.border,
    }
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {" " .. rtl_text .. " "})
    
    local win = vim.api.nvim_open_win(buf, false, opts)
    vim.api.nvim_win_set_option(win, "winhl", "Normal:" .. M.config.highlight)
    
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, 3000)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  if M.config.enabled then
    vim.api.nvim_create_autocmd("CursorHold", {
      pattern = "*",
      callback = show_rtl_hover,
      desc = "Show RTL hover for Arabic text"
    })
  end
end

function M.toggle()
  M.config.enabled = not M.config.enabled
  print("Hover RTL: " .. (M.config.enabled and "enabled" or "disabled"))
end

function M.show_hover()
  show_rtl_hover()
end

return M