local motions = require("scm-edit.motions")
local parens  = require("scm-edit.parens")

return {
   setup = function()
      vim.keymap.set({'n', 'x', 'o'}, 'W',  motions.next_form_start)
      vim.keymap.set({'n', 'x', 'o'}, 'B',  motions.prev_form_start)
      vim.keymap.set({'n', 'x', 'o'}, 'w',  motions.next_element_start)
      vim.keymap.set({'n', 'x', 'o'}, 'b',  motions.prev_element_start)
      vim.keymap.set({'n', 'x', 'o'}, 'e',  motions.next_element_end)
      --vim.keymap.set({'n', 'x', 'o'}, 'ge', motions.prev_element_end)

      vim.keymap.set('i', '<C-j>', parens.close_all)
      vim.keymap.set('i', '<C-k>', parens.close_one)
      vim.keymap.set('n', 'st'   , parens.toggle)
   end,
}

--[[

Preferable if using an <expr> map to use <cmd>, as it doesn't leave the current
mode to enter commandline mode. Don't think I'll be using <expr> maps, but it's
something to consider.

Might want to do a bit of super unscientific testing, see if either "feels"
more responsive when very rapidly moving through text.

E.g.,
$ xset r rate 10 500

Need to try the following:
```lua
vim.keymap.set('n', 'w', function()
   return '<cmd>normal! w'
end, { expr=true })

vim.keymap.set('n', 'w', function()
   vim.cmd('normal! w')
end)
```

--]]
