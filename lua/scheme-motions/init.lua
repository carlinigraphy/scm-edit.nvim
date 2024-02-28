local Cursor     = require("scheme-motions.cursor")
local motions    = require("scheme-motions.motions")
local predicates = require("scheme-motions.predicates")

local M = {}

function M.setup()
   vim.keymap.set('n', 's', motions.next_form_start)
   --vim.keymap.set('n', 's', function()
   --   local c = Cursor.get()
   --   print(c)
   --end)
end

return M
