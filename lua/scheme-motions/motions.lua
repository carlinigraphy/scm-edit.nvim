local M = {}

local ts = require("nvim-treesitter.ts_utils")
local pred = require("predicates")
local Cursor = require("cursor")

---@param node TSNode
---@return TSNode?
--
-- Depth-first search, returning in order:
--  1. First child (if found)
--  2. Next sibling (if found)
-- Recurse up the tree until hitting the document root.
local function next_named(node)
   if node:named_child_count() > 0 then
      return node:named_child(0)
   end

   repeat
      if node:next_named_sibling() then
         return node:next_named_sibling()
      end
      ---@diagnostic disable-next-line: cast-local-type
      node = node:parent()
   until
      ---@diagnostic disable-next-line: need-check-nil
      not node:parent()
end


--- Advances cursor (skipping comments) to the start of the next form.
function M.next_form_start()
  local cursor = Cursor.get()
  local node   = ts.get_node_at_cursor()

  repeat node = next_named(node) --[[@as TSNode]]
  until  cursor:is_behind(node) and
         not pred.is_form(node) and
         not pred.is_comment(node)

  if node then
    cursor:set(node, "start")
  end
end

return M
