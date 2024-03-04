--[[ THINKIES

Wrapping TSNode object. Return some metatable closure nonsense to allow access
to underlying TSNode objects, and added methods.

Would be kinda cool to have this be a bit more modular. Allow dynamic loading
functions to the Node object, depending on what functionality is needed.

Can add my version of the "prev_node" function, returning the previous
(flattened) node.

--]]

local ts = require("nvim-treesitter.ts_utils")

---@class Node
local Node = {}

function Node:text()
   return ts.get_node_text(self)
end


---@param TSNode TSNode
---@return Node
function Node:new(TSNode)
   return setmetatable({}, {
      __index = function(_, key)
         local rv = self[key]
         if rv then return rv end

         -- Don't know if this is necessary, but should give better error
         -- reporting.
         if not TSNode[key] then
            error("Key '"..key.."' not found.", 2)
         end

         return function(...)
            return TSNode[key](TSNode, ...)
         end
      end
   })
end


return Node
