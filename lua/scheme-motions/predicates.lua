--[[ THINKIES:

Not sure if I want to just wrap the entire TSNode w/ new methods, or just
provide a new module to interact with them.

--]]

local M = {}

---@param node TSNode
function M.is_comment(node)
   return node:type() == "comment" or
          node:type() == "block_comment"
end


---@param node TSNode
function M.is_form(node)
   return node:type() == "list"   or
          node:type() == "vector" or
          node:type() == "byte_vector"
end


---@param node TSNode
--
-- Depth-first search, returning in order:
--  1. First child (if found)
--  2. Next sibling (if found)
-- Recurse up the tree until hitting the document root.
function M.next_named(node)
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

return M
