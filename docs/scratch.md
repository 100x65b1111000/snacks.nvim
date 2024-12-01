# 🍿 scratch

![image](https://gist.github.com/user-attachments/assets/0bed05c5-371c-43fe-a525-793012e5cbd9)
![image](https://gist.github.com/user-attachments/assets/a202ec17-5826-407a-aa28-18b87004d04a)

## 🚀 Usage

Suggested config:

```lua
{
  "folke/snacks.nvim",
  keys = {
    { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
  }
}
```

<!-- docgen -->

## ⚙️ Config

```lua
---@class snacks.scratch.Config
---@field win? snacks.win.Config scratch window
---@field template? string template for new buffers
---@field file? string scratch file path. You probably don't need to set this.
{
  name = "Scratch",
  ft = "lua",
  ---@type string|string[]?
  icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
  root = vim.fn.stdpath("data") .. "/scratch",
  autowrite = true, -- automatically write when the buffer is hidden
  -- unique key for the scratch file is based on:
  -- * name
  -- * ft
  -- * vim.v.count1 (useful for keymaps)
  -- * cwd (optional)
  -- * branch (optional)
  filekey = {
    cwd = true, -- use current working directory
    branch = true, -- use current branch name
    count = true, -- use vim.v.count1
  },
  win = { style = "scratch" },
  ---@type table<string, snacks.win.Config>
  win_by_ft = {
    lua = {
      keys = {
        ["source"] = {
          "<c-s>",
          function()
            if vim.fn.mode():match("[vV]") then
              vim.fn.feedkeys(":", "nx")
              vim.cmd([['<,'>source]])
              vim.fn.feedkeys("gv", "n")
            else
              vim.cmd([[source]])
            end
          end,
          desc = "Source buffer",
          mode = { "n", "x" },
        },
      },
    },
  },
}
```

## 🎨 Styles

### `scratch`

```lua
{
  width = 100,
  height = 30,
  bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
  minimal = false,
  noautocmd = false,
  -- position = "right",
  zindex = 20,
  wo = { winhighlight = "NormalFloat:Normal" },
  border = "rounded",
  title_pos = "center",
  footer_pos = "center",
}
```

## 📚 Types

```lua
---@class snacks.scratch.File
---@field file string full path to the scratch buffer
---@field stat uv.fs_stat.result File stat result
---@field name string name of the scratch buffer
---@field ft string file type
---@field icon? string icon for the file type
---@field cwd? string current working directory
---@field branch? string Git branch
---@field count? number vim.v.count1 used to open the buffer
```

## 📦 Module

### `Snacks.scratch()`

```lua
---@type fun(opts?: snacks.scratch.Config): snacks.win
Snacks.scratch()
```

### `Snacks.scratch.list()`

Return a list of scratch buffers sorted by mtime.

```lua
---@return snacks.scratch.File[]
Snacks.scratch.list()
```

### `Snacks.scratch.open()`

Open a scratch buffer with the given options.
If a window is already open with the same buffer,
it will be closed instead.

```lua
---@param opts? snacks.scratch.Config
Snacks.scratch.open(opts)
```

### `Snacks.scratch.select()`

Select a scratch buffer from a list of scratch buffers.

```lua
Snacks.scratch.select()
```
