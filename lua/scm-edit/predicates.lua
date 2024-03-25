local M = {}


--[[ TODO;
Considering putting all of the predicates for jumping to forms/elements here as
well. Maybe abstract them a little more? Function that builds predicates does
seem a bit unncessary though.

function element_pred(direction, side)
   local cursor_cmp
   if direction == "prev" then
      cursor_cmp = cursor.is_ahead
   elseif direction == "next" then
      cursor_cmp = cursor.is_behind
   end

   return function(node, cursor)
      return node
         and not pred.is_form(node)
         and not pred.is_comment(node)
         and cursor_cmp(cursor, node, side)
   end)
end
--]]


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


return M
