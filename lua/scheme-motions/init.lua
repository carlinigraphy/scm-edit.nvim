local motions = require("scheme-motions.motions")

local M = {}

function M.setup()
   vim.keymap.set('n', 'W', motions.next_form_start)
   vim.keymap.set('n', 'B', motions.prev_form_start)
   vim.keymap.set('n', 'w', motions.next_element_start)
   vim.keymap.set('n', 'b', motions.prev_element_start)
   vim.keymap.set('n', 'e', motions.next_element_end)
end

return M
