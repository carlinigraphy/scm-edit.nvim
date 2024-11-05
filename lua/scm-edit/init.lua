local motions = require("scm-edit.motions")
local parens  = require("scm-edit.parens")

return {
   setup = function()
      local opts = { buffer=true }

      -- Preserve default bindings w/ currently unused g_ maps.
      vim.keymap.set({'n', 'x', 'o'}, 'gb', [[normal! b]], opts)
      vim.keymap.set({'n', 'x', 'o'}, 'gB', [[normal! B]], opts)
      vim.keymap.set({'n', 'x', 'o'}, 'gw', [[normal! w]], opts)
      vim.keymap.set({'n', 'x', 'o'}, 'gW', [[normal! W]], opts)

      vim.keymap.set({'n', 'x', 'o'}, 'b',  motions.prev_element_start, opts)
      vim.keymap.set({'n', 'x', 'o'}, 'w',  motions.next_element_start, opts)

      vim.keymap.set({'n', 'x'}, 'e',  motions.next_element_end, opts)
      vim.keymap.set({'n', 'x'}, 'ge', motions.prev_element_end, opts)

      vim.keymap.set({'n', 'x', 'o'}, 'B',  motions.prev_form_start, opts)
      vim.keymap.set({'n', 'x', 'o'}, 'W',  motions.next_form_start, opts)

      --vim.keymap.set('i', '<C-j>', parens.close_all, opts)
      --vim.keymap.set('i', '<C-k>', parens.close_one, opts)
      vim.keymap.set('n', 'st'   , parens.toggle   , opts)
   end,
}
