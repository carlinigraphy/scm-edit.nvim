local motions = require("scm-edit.motions")
local parens  = require("scm-edit.parens")

return {
   setup = function()
      -- Preserve default bindings w/ currently unused g_ maps.
      vim.keymap.set({'n', 'x', 'o'}, 'gb', [[normal! b]])
      vim.keymap.set({'n', 'x', 'o'}, 'gB', [[normal! B]])
      vim.keymap.set({'n', 'x', 'o'}, 'gw', [[normal! w]])
      vim.keymap.set({'n', 'x', 'o'}, 'gW', [[normal! W]])

      vim.keymap.set({'n', 'x', 'o'}, 'b',  motions.prev_element_start)
      vim.keymap.set({'n', 'x', 'o'}, 'w',  motions.next_element_start)

      vim.keymap.set({'n', 'x', 'o'}, 'e',  motions.next_element_end)
      vim.keymap.set({'n', 'x', 'o'}, 'ge', motions.prev_element_end)

      vim.keymap.set({'n', 'x', 'o'}, 'B',  motions.prev_form_start)
      vim.keymap.set({'n', 'x', 'o'}, 'W',  motions.next_form_start)

      vim.keymap.set('i', '<C-j>', parens.close_all)
      vim.keymap.set('i', '<C-k>', parens.close_one)
      vim.keymap.set('n', 'st'   , parens.toggle)
   end,
}
