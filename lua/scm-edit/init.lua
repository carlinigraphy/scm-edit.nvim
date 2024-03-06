local motions = require("scm-edit.motions")
local pairs   = require("scm-edit.pairs")
local pred    = require("scm-edit.predicates")

--[[

Things to use now:

vim.v.count1
   Returns count to a motion, starting at `1' if no count is provided.

--]]


return {
   setup = function()
      _G.scm_edit = require("scm-edit")

      vim.keymap.set({'n', 'x', 'o'}, 'W', [[\
         v:lua.scm_edit.in_comment() ? "W" : ":lua scm_edit.next_form_start()<CR>"
      ]], { expr=true, silent=true })

      vim.keymap.set({'n', 'x', 'o'}, 'B', [[
         v:lua.scm_edit.in_comment() ? "B" : ":lua scm_edit.prev_form_start()<CR>"
      ]], { expr=true, silent=true })

      vim.keymap.set({'n', 'x', 'o'}, 'w', [[
         v:lua.scm_edit.in_comment() ? "w" : ":lua scm_edit.next_element_start()<CR>"
      ]], { expr=true, silent=true })

      vim.keymap.set({'n', 'x', 'o'}, 'b', [[
         v:lua.scm_edit.in_comment() ? "b" : ":lua scm_edit.prev_element_start()<CR>"
      ]], { expr=true, silent=true })

      vim.keymap.set({'n', 'x', 'o'}, 'e', [[
         v:lua.scm_edit.in_comment() ? "e" : ":lua scm_edit.next_element_end()<CR>"
      ]], { expr=true, silent=true })

      vim.keymap.set('i', '<C-j>', pairs.close_all)
      vim.keymap.set('i', '<C-k>', pairs.close_one)
      vim.keymap.set('n', 'st'   , pairs.toggle)
   end,

   -- Predicates.
   in_comment          = pred.in_comment,

   -- Pairs.
   close_all_pairs     = pairs.close_all,
   close_one_pair      = pairs.close_one,
   toggle_pair         = pairs.toggle,

   -- Motions.
   next_form_start     = motions.next_form_start,
   prev_form_start     = motions.prev_form_start,
   next_element_start  = motions.next_element_start,
   prev_element_start  = motions.prev_element_start,
   next_element_end    = motions.next_element_end,
}
