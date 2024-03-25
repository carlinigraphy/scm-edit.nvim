local M = {}


---@param node TSNode
---@return boolean
function M.is_comment(node)
   assert(node)
   local type = node:type()
   return
      type == "comment" or
      type == "block_comment"
end


---@param node TSNode
---@return boolean
function M.is_form(node)
   assert(node)
   local type = node:type()
   return
      type == "program"   or
      type == "list"      or
      type == "vector"    or
      type == "byte_vector"
end


---@param node TSNode
---@return boolean
function M.is_string(node)
   assert(node)
   local type = node:type()
   return
      type == "string" or
      type == "escape_sequence"
end


return M
