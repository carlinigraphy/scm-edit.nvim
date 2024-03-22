local M = {}


---@param node TSNode
---@return boolean
function M.is_comment(node)
   assert(node)
   return
      node:type() == "comment" or
      node:type() == "block_comment"
end


---@param node TSNode
---@return boolean
function M.is_form(node)
   assert(node)
   return
      node:type() == "program"   or
      node:type() == "list"      or
      node:type() == "vector"    or
      node:type() == "byte_vector"
end


return M
