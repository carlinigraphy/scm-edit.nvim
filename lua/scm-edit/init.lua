local motions = require("scm-edit.motions")
local parens  = require("scm-edit.parens")

return {
   setup = function()
      vim.keymap.set({'n', 'x', 'o'}, 'sp',    motions.prev_element_start)
      vim.keymap.set({'n', 'x', 'o'}, '<C-p>', motions.prev_form_start)

      vim.keymap.set({'n', 'x', 'o'}, 'sn',    motions.next_element_start)
      vim.keymap.set({'n', 'x', 'o'}, '<C-n>', motions.next_form_start)

      vim.keymap.set('i', '<C-j>', parens.close_all)
      vim.keymap.set('i', '<C-k>', parens.close_one)
      vim.keymap.set('n', 'st'   , parens.toggle)
   end,
}
