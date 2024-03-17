local M = {}

local ts = require("nvim-treesitter.ts_utils")

local pred = require("scm-edit.predicates")
local Cursor = require("scm-edit.cursor")
local Context = require("scm-edit.context")

local MAX_RECR = 1000

---@param node TSNode
---@return TSNode
--
-- Depth-first search, returning in order:
--    1. First child (if found)
--    2. Next sibling (if found)
-- Recurse up the tree until hitting the document root.
local function next_named(node)
   assert(node)

   if node:named_child_count() > 0 then
      return node:named_child(0) --[[@as TSNode]]
   end

   repeat
      if node:next_named_sibling() then
         return node:next_named_sibling() --[[@as TSNode]]
      end
      node = node:parent() --[[@as TSNode]]
   until not node:parent()

   -- TODO:
   -- I need to rethink this a bit. Are there any situations under which this
   -- function would not return a node?
   return node
end


---@param node TSNode
---@return TSNode?
--
-- Depth first backwards search, returning in order:
--    1. Previous sibling's deepest leaf node
--    2. Node's parent
local function prev_named(node)
   assert(node)

   if not node:prev_named_sibling() then
      return node:parent()
   end

   node = node:prev_named_sibling()
   while node:named_child_count() > 0 do
      node = node:named_child(node:named_child_count() - 1)
   end

   return node
end


---@param start_node TSNode
---@param direction  "next"  | "prev"
---@param side       "start" | "end"
---@param predicate  fun(node: TSNode, cursor: Cursor): boolean
--
---@return TSNode
--
-- Sets cursor location to the next TSNode matching a predicate. Repeaatedly
-- calls `next_node()` or `prev_node()` until `predicate(node, cursor)` is
-- true.
local function move_to(start_node, direction, side, predicate)
   local cursor = Cursor:get()

   local fn
   if direction == "prev" then
      fn = prev_named
   elseif direction == "next" then
      fn = next_named
   else
      error("Expecting non-nil TSNode.", 2)
   end

   local recr = MAX_RECR
   local target_node = start_node

   repeat
      target_node = fn(target_node) --[[@as TSNode]]
      recr = recr - 1
   until
      predicate(target_node, cursor) or
      recr < 0

   if recr < 0 then
      error("Maximum recursion depth hit.")
   end

   if target_node then
      cursor:set(target_node, side)
   end

   return target_node
end


--- Unvances cursor (skipping comments) to the start of the previous form.
function M.prev_form_start()
   local start_node, context = Context:at_cursor()

   if context == Context.COMMENT then
      return vim.cmd('normal! B')
   else
      move_to(start_node, "prev", "start", function(node, cursor)
         return not node
            or  pred.is_form(node)
            and cursor:is_ahead(node, "start")
      end)
   end
end


function M.prev_element_start()
   local start_node, context = Context:at_cursor()

   if context == Context.COMMENT then
      return vim.cmd('normal! b')
   else
      move_to(start_node, "prev", "start", function(node, cursor)
         return not node
            or not pred.is_form(node)
            and cursor:is_ahead(node, "start")
      end)
   end
end


-- Advances cursor (skipping comments) to the start of the next form.
function M.next_form_start()
   local start_node, context = Context:at_cursor()

   if context == Context.COMMENT then
      return vim.cmd('normal! W')
   else
      move_to(start_node, "next", "start", function(node, cursor)
         return not node
            or pred.is_form(node)
            and cursor:is_behind(node, "start")
      end)
   end
end


function M.next_element_start()
   local start_node, context = Context:at_cursor()

   if context == Context.COMMENT then
      return vim.cmd('normal! w')
   else
      move_to(start_node, "next", "start", function(node, cursor)
         return not node
            or not pred.is_form(node)
            and cursor:is_behind(node, "start")
      end)
   end
end


function M.next_element_end()
   local start_node, context = Context:at_cursor()

   if context == Context.COMMENT then
      return vim.cmd('normal! e')
   else
      move_to(start_node, "next", "end", function(node, cursor)
         return not node
            or not pred.is_form(node)
            and cursor:is_behind(node, "end")
      end)
   end
end


--[[
Think I tried to abstract away the movement functionality a bit too much. Turns
out there are subtle differences to account for in either direction.

`e` (element end) should first go to the end of the current element. Only if on
the last char of the current element should it advance to the next.

There is always the "inside a form" problem, when cursor is like this:
   (one two | three)

The "previous" and "next" form will be with respect to the container, not the
inner node. Especaily a problem when the cursor is on the closing paren. Is
treated the same as if its on the opening.

The most important part is predictability! Must behave in a manner that is
consistent, with no edge cases. Shouldn't need to re-learn how to move, should
move how it makes sense to do so.

First get everything working, then abstract.
--]]


--[[ Moving backwards
[ ] Target *side* of target node must be behind the cursor. First checking the
    current node itself.

    E.g., given
      wor|d
    the cursor should jump to the beginning before going to the prior word.
--]]


---@param node       TSNode
---@param cursor     Cursor
---@param direction  "prev" | "next"
---@param predicate  fun(node: TSNode?, cursor: Cursor): boolean
--
---@return TSNode
local function move_while(node, cursor, direction, predicate)
   local fn
   if direction == "prev" then
      fn = prev_named
   elseif direction == "next" then
      fn = next_named
   else
      error("'direction' expecting one of: ['prev', 'next']", 2)
   end

   local new_node = fn(node)
   if predicate(new_node, cursor) then
      return new_node
   else
      return move_while(new_node, cursor, direction, predicate)
   end
end


--[=[
---@param node TSNode
---@return TSNode
--
-- Returns last named node of a form. Ideally this would stop when hitting the
-- first node that is not behind the cursor... but for now it will suffice.
--
-- So... it turns out this was wholly unnecessary. It can be entirely replaced
-- with a recursive `named_child[-1]` call. Little unnnecessary cursor
-- movement, and a single API call. Probably faster than trying to iterate
-- myself in the shortest number of hops.
local function end_of_form(node)
   local num_children = node:named_child_count()
   local next_sibling = node:next_named_sibling()
   local next_child   = node:named_child(num_children - 1)

   if next_child then
      return end_of_form(next_child)
   elseif next_sibling then
      return end_of_form(next_sibling)
   else
      return node
   end
end
--]=]


---@diagnostic disable-next-line: duplicate-set-field
function M.prev_element_start()
   --[[ THUS FAR;
   Current state of my thinkies.

   If element is a form, we're either in the whitespace, the start paren, or
      the end paren. 

   If in the whitespace, the easiest solution (I've thought of) is to seek to
      the final named child before beginning a search backwards. Must search
      recursively, in case last child is itself a form. Else we're just in the
      same boat again.

   If there are no children, the current node is returned. This will either the
      start or end tokens. Doesn't matter, as beginning the `move_while()`
      search will seek to the prior *element*.
   --]]

   --[[ WHAT DOESN'T WORK;
   Jumping backwards from the final `)' of a form skips one element. Maybe an
      issue with the cursor check?
   --]]

   local node = ts.get_node_at_cursor() --[[@as TSNode]]
   local cursor = Cursor:get()

   while node
      and pred.is_form(node)
      and (node:named_child_count() > 0)
   do
      node = node:named_child(node:named_child_count() - 1)
   end

   --[[DEBUG
   -- For determining the position of the cursor within the node. May be
   -- helpful to either make some new predicates, or new cursor methods.
   --    * Cursor:is_inner_not_start()
   --    * Cursor:is_inner_not_end()
   -- Not as an end goal, as it's still kinda hacky and weird. But perhaps an
   -- intermediate solution.
   local start_row, start_col, _, end_col = node:range()

   -- Go to the start of the node itself. If cursor is within, but after the
   -- first character.
   if (cursor.row    == start_row) and
      (cursor.column  > start_col) and
      (cursor.column <= end_col)
   then
      return cursor:set(node, "start")
   end
   --]]

   repeat
      node = prev_named(node)
   until node
      and not pred.is_form(node)
      and not pred.is_comment(node)
      and cursor:is_ahead(node, "end")

   if node then
      cursor:set(node, "start")
   end

   return node
end


return M
