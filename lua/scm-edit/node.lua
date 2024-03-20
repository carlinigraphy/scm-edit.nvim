--[[ THINKIES

Wrapping TSNode object. Return some metatable closure nonsense to allow access
to underlying TSNode objects, and added methods.

Would be kinda cool to have this be a bit more modular. Allow dynamic loading
functions to the Node object, depending on what functionality is needed.

Can add my version of the "prev_node" function, returning the previous
(flattened) node.

--]]

---@class Node
local Node = {
   get  = vim.treesitter.get_node,
   text = vim.treesitter.get_node_text,
}


---@param node TSNode
---@return Node
function Node:new(node)
   -- Pretty safe to assume *one* of these will be necessary every time.
   local start_row, start_column, end_row, end_column = node:range()

   return setmetatable({
      start_row    = start_row,
      start_column = start_column,
      end_row      = end_row,
      end_column   = end_column - 1,  -- non-inclusive upper bound offset.
   }, {
      __index = function(_, key)
         local rv = self[key]
         if rv then return rv end

         -- Don't know if this is necessary, but should give better error
         -- reporting.
         if not node[key] then
            error("Key '"..key.."' not found.", 2)
         end

         return function(...)
            return node[key](node, ...)
         end
      end
   })
end


return Node
