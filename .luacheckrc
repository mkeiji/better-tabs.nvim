-- Luacheck configuration for better-gtd.nvim
-- See https://luacheck.readthedocs.io/en/stable/config.html for details

globals {
  -- Neovim globals
  "vim",
  
  -- Plugin globals (if any)
  "better_gtd",
}

unused_args = false
self = false
ignore = {
  "631",  -- max_line_length
  "211/_", -- unused variable beginning with underscore
  "212/_", -- unused argument beginning with underscore
}
