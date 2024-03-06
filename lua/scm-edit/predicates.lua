local ts = require("nvim-treesitter.ts_utils")

local M = {}


---@return boolean
--
-- Differs from **M.is_comment()** in that it checks the cursors current
-- position. Useful as a predicate in binding conditional macros.
--
-- ```lua
-- vim.keymap.set('n', 'w', [[
--   v:lua.scm_edit.in_comment() ? "w" : "v:lua.scm_edit.next_element_start()<CR>"
-- ]], { expr=true, silent-true })
-- ```
function M.in_comment()
   local node = ts.get_node_at_cursor()
   return M.is_comment(node)
end



---@param node TSNode
---@return boolean
function M.is_comment(node)
   return node:type() == "comment" or
          node:type() == "block_comment"
end


---@param node TSNode
---@return boolean
function M.is_form(node)
   return node:type() == "list"   or
          node:type() == "vector" or
          node:type() == "byte_vector"
end

return M
