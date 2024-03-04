--[[ pairs

Provide (very limited) auto-pairs functionality. Will close the corresponding
opened symbol in the tree of direct ancestors.

Seems this can be done by searching up for a :parent() ERROR node.

Example, the following code...

```scheme
(define (one two
```

...produces this parse tree...

```query
ERROR [6, 0] - [7, 0]
  "(" [6, 0] - [6, 1]
  symbol [6, 1] - [6, 7]
  "(" [6, 8] - [6, 9]
  symbol [6, 9] - [6, 12]
  symbol [6, 13] - [6, 16]
```

My initial assumption is:
   1. Walk up the tree
   2. Push the inverse of each unmatched bracket to the stack
   3. Append them all

Can skip well-formed containers, such as `list's. E.g.,,

```scheme
(define (one two) (
```

```query
ERROR [6, 0] - [7, 0]
  "(" [6, 0] - [6, 1]
  symbol [6, 1] - [6, 7]
  list [6, 8] - [6, 17]
    "(" [6, 8] - [6, 9]
    symbol [6, 9] - [6, 12]
    symbol [6, 13] - [6, 16]
    ")" [6, 16] - [6, 17]
  "(" [6, 18] - [6, 19]
```

At the level of the `ERROR' there are two anonymous open-paren nodes. Contrary
to the `list' element, which has a well-formed open/close pair.

--]]

local Cursor = require("scheme-motions.cursor")
local pred   = require("scheme-motions.predicates")
local ts = require("nvim-treesitter.ts_utils")

local get_node_text = vim.treesitter.get_node_text

local M = {}


---@param node  TSNode
---@return string
local function collect_parens(node)
   local stack = ""
   local matching = {
      ["("] = ")",
      ["["] = "]",
      ["{"] = "}",
   }

   for child in node:iter_children() do
      stack = (
         not child:named()
         and matching[get_node_text(child, 0)]
         or ""
      ) .. stack
   end

   return stack
end


function M.close_one()
   local cursor = Cursor:get()
   local node   = ts.get_node_at_cursor()

   local parens = collect_parens(node)
   vim.api.nvim_buf_set_text(0,
      cursor.row, cursor.column, -- start row/col
      cursor.row, cursor.column, -- end row/col
      { string.sub(parens, 1, 1) }
   )

   cursor:set_offset({ column = 1 })
end


function M.close_all()
   local cursor = Cursor:get()
   local node = ts.get_node_at_cursor()

   local parens = collect_parens(node)
   vim.api.nvim_buf_set_text(0,
      cursor.row, cursor.column, -- start row/col
      cursor.row, cursor.column, -- end row/col
      { parens, "" }
   )
   cursor:set_offset({ row = 1 })
end


function M.toggle()
   local node = ts.get_node_at_cursor()
   local matching = {
      ["("] = "[", [")"] = "]",
      ["["] = "(", ["]"] = ")",
   }

   if node:type() ~= 'list' then
      return
   end

   local open_node  = node:child(0)
   local open_match = matching[get_node_text(open_node, 0)]
   local open_row, open_col = node:start()

   vim.api.nvim_buf_set_text(0,
      open_row, open_col,
      open_row, open_col+1,
      { open_match }
   )

   local close_node  = node:child(node:child_count()-1)
   local close_match = matching[get_node_text(close_node, 0)]
   local close_row, close_col = close_node:start()

   vim.api.nvim_buf_set_text(0,
      close_row, close_col,
      close_row, close_col+1,
      { close_match }
   )
end


return M
