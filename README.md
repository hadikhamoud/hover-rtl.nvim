# hover-rtl.nvim

A Neovim plugin that displays Arabic text in RTL (right-to-left) format when hovering over it.


### Using lazy.nvim

```lua
{
  "hadikhamoud/hover-rtl.nvim",
  config = function()
    require("hover-rtl").setup({
      enabled = true,
      border = "rounded",
      highlight = "NormalFloat",
    })
  end,
}
```

