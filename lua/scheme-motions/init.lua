local motions = require("scheme-motions.motions")

local M = {}

function M.setup()
   vim.keymap.set('n', 'W', motions.next_form_start)
   vim.keymap.set('n', 'B', motions.prev_form_start)
end

return M
