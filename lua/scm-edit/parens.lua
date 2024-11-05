--------------------------------------------------------------------------------
-- internals
--------------------------------------------------------------------------------
local Cursor = require("scm-edit.cursor")
local get_node_text = vim.treesitter.get_node_text

---@param node  TSNode
---@return string
local function collect_parens(node)
   local stack = ""
   for child in node:iter_children() do
      stack = (
         not child:named()
         or ""
      ) .. stack
   end
   return stack
end


--------------------------------------------------------------------------------
-- externals
--------------------------------------------------------------------------------
local M = {}


function M.close_one()
   local cursor, node = Cursor:get()
   local parens = collect_parens(node)
   vim.api.nvim_buf_set_text(0,
      cursor.row, cursor.column, -- start row/col
      cursor.row, cursor.column, -- end row/col
      { string.sub(parens, 1, 1) }
   )
   cursor:set_offset({ column = 1 })
end


function M.close_all()
   local cursor, node = Cursor:get()
   local parens = collect_parens(node)
   vim.api.nvim_buf_set_text(0,
      cursor.row, cursor.column, -- start row/col
      cursor.row, cursor.column, -- end row/col
      { parens, "" } -- add empty line after
   )
   cursor:set_offset({ row = 1 })
end


function M.toggle()
   local node = Cursor.get_node()
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
