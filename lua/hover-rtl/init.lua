local M = {}

M.config = {
	enabled = true,
	border = "rounded",
	highlight = "NormalFloat",
}

local current_hover_win = nil
local last_cursor_pos = nil

local function is_arabic_text(text)
	local i = 1
	while i <= #text do
		local byte = text:byte(i)
		local char_len = 1

		if byte >= 240 then -- 4-byte UTF-8
			char_len = 4
		elseif byte >= 224 then -- 3-byte UTF-8
			char_len = 3
		elseif byte >= 192 then -- 2-byte UTF-8
			char_len = 2
		end

		if char_len > 1 then
			local char = text:sub(i, i + char_len - 1)
			local codepoint = vim.fn.char2nr(char)

			-- Arabic ranges: 0x0600-0x06FF, 0x0750-0x077F, 0x08A0-0x08FF, 0xFB50-0xFDFF, 0xFE70-0xFEFF
			if
				(codepoint >= 0x0600 and codepoint <= 0x06FF)
				or (codepoint >= 0x0750 and codepoint <= 0x077F)
				or (codepoint >= 0x08A0 and codepoint <= 0x08FF)
				or (codepoint >= 0xFB50 and codepoint <= 0xFDFF)
				or (codepoint >= 0xFE70 and codepoint <= 0xFEFF)
			then
				return true
			end
		end

		i = i + char_len
	end

	return false
end

local function close_current_hover()
	if current_hover_win and vim.api.nvim_win_is_valid(current_hover_win) then
		vim.api.nvim_win_close(current_hover_win, true)
		current_hover_win = nil
	end
end

local function show_rtl_hover()
	-- Only show hover in normal mode (not insert, visual, etc.)
	local mode = vim.api.nvim_get_mode().mode
	if mode ~= "n" then
		close_current_hover()
		return
	end

	-- Don't trigger if cursor is in a floating window (hover window)
	local current_win = vim.api.nvim_get_current_win()
	local win_config = vim.api.nvim_win_get_config(current_win)
	if win_config.relative ~= "" then
		return
	end

	local current_line = vim.api.nvim_get_current_line()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	-- Check if cursor moved significantly
	if
		last_cursor_pos
		and (math.abs(cursor_pos[1] - last_cursor_pos[1]) > 0 or math.abs(cursor_pos[2] - last_cursor_pos[2]) > 5)
	then
		close_current_hover()
	end

	last_cursor_pos = cursor_pos

	-- Check if line is under 1000 characters and contains Arabic
	if #current_line >= 1000 or not is_arabic_text(current_line) then
		close_current_hover()
		return
	end

	-- Don't show hover if one is already displayed for this position
	if current_hover_win and vim.api.nvim_win_is_valid(current_hover_win) then
		return
	end

	-- Skip empty lines
	if current_line:match("^%s*$") then
		return
	end

	-- Display Arabic text as-is (no reversal) - let terminal handle RTL
	local rtl_text = current_line

	-- Ensure we have valid content
	if not rtl_text or rtl_text == "" then
		return
	end

	-- Create floating window manually to have full control over Arabic settings
	local width = math.min(vim.fn.strwidth(rtl_text) + 4, vim.o.columns - 4)
	local height = 1

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { rtl_text })

	local opts = {
		relative = "cursor",
		width = width,
		height = height,
		row = 1,
		col = 0,
		style = "minimal",
		border = M.config.border,
	}

	current_hover_win = vim.api.nvim_open_win(buf, false, opts)

	-- Enable Arabic mode specifically for this window
	vim.api.nvim_win_set_option(current_hover_win, "arabic", true)
	vim.api.nvim_buf_set_option(buf, "arabic", true)
	vim.api.nvim_win_set_option(current_hover_win, "winhl", "Normal:" .. M.config.highlight)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if M.config.enabled then
		vim.api.nvim_create_autocmd("CursorHold", {
			pattern = "*",
			callback = show_rtl_hover,
			desc = "Show RTL hover for Arabic text",
		})

		-- Add CursorMoved to close hover when moving away
		vim.api.nvim_create_autocmd("CursorMoved", {
			pattern = "*",
			callback = function()
				local cursor_pos = vim.api.nvim_win_get_cursor(0)
				if
					last_cursor_pos
					and (
						math.abs(cursor_pos[1] - last_cursor_pos[1]) > 0
						or math.abs(cursor_pos[2] - last_cursor_pos[2]) > 5
					)
				then
					close_current_hover()
				end
			end,
			desc = "Close RTL hover when cursor moves",
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
