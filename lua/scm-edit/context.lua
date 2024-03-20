local Cursor = require("scm-edit.cursor")
local pred   = require("scm-edit.predicates")
local ts     = require("nvim-treesitter.ts_utils")

--[[ THINKIES

Unsure if I want this to actually be a module. It's kinda just a wrapper around
integers. Whole thing could realistically be the `context_map` function.

--]]


---@enum Context
Context = {
   COMMENT = 1,
   CODE    = 2,
}


---@param  node TSNode
---@return Context
local function context_map(node)
   if pred.is_comment(node) then
      return Context.COMMENT
   else
      return Context.CODE
   end
end


---@return TSNode, Context
function Context:at_cursor()
   local node = Cursor.get_node_at_cursor()
   return node, context_map(node)
end


---@param node TSNode
---@return Context
function Context:from_node(node)
   return context_map(node)
end


return Context
