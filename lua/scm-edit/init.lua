local motions = require("scm-edit.motions")
local pairs = require("scm-edit.pairs")

local M = {}


function M.setup()
   vim.keymap.set({'n', 'x', 'o'}, 'W', motions.next_form_start)
   vim.keymap.set({'n', 'x', 'o'}, 'B', motions.prev_form_start)
   vim.keymap.set({'n', 'x', 'o'}, 'w', motions.next_element_start)
   vim.keymap.set({'n', 'x', 'o'}, 'b', motions.prev_element_start)
   vim.keymap.set({'n', 'x', 'o'}, 'e', motions.next_element_end)

   vim.keymap.set('i'            , '<C-j>', pairs.close_all)
   vim.keymap.set('i'            , '<C-k>', pairs.close_one)
   vim.keymap.set('n'            , 'st'   , pairs.toggle)
end


return M
