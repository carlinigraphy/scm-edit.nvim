local Cursor = require("scm-edit.cursor")
local pred   = require("scm-edit.predicates")

--[[ THINKIES
Unsure if I want this to actually be a module. It's kinda just a wrapper around
integers. Whole thing could realistically be the `context_map` function.
--]]


---@enum Context
Context = {
   CODE    = 1,
   COMMENT = 2,
   STRING  = 3,
}


---@param  node TSNode
---@return Context
local function context_map(node)
   if pred.is_comment(node) then
      return Context.COMMENT
   elseif pred.is_string(node) then
      return Context.STRING
   else
      return Context.CODE
   end
end


---@return Context
function Context:at_cursor()
   return context_map(Cursor.get_node())
end


---@param node TSNode
---@return Context
function Context:from_node(node)
   return context_map(node)
end


return Context
