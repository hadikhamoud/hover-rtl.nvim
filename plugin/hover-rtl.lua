if vim.g.loaded_hover_rtl then
  return
end
vim.g.loaded_hover_rtl = 1

vim.api.nvim_create_user_command("HoverRtlToggle", function()
  require("hover-rtl").toggle()
end, {
  desc = "Toggle Arabic RTL hover display"
})

vim.api.nvim_create_user_command("HoverRtlShow", function()
  require("hover-rtl").show_hover()
end, {
  desc = "Manually show RTL hover for current word"
})

if vim.g.hover_rtl_auto_setup ~= false then
  require("hover-rtl").setup()
end