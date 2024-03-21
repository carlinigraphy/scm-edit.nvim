-- vim: foldmethod=marker

local M = {}

local pred = require("scm-edit.predicates")
local Cursor = require("scm-edit.cursor")
local Context = require("scm-edit.context")

local MAX_RECR = 1000

---@param node TSNode
---@return TSNode?
--
-- Depth-first search, returning in order:
--    1. First child (if found)
--    2. Next sibling (if found)
--
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
end

-- TODO;
--
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


-- Advances cursor (skipping comments) to the start of the next form.
function M.next_form_start()
   local start_node, context = Context:at_cursor()
   vim.cmd[[ normal! m' ]] -- effectively pushes loc to jumplist

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


-- [GOOD] -------------------------------------------------------------------{{{

---@param node TSNode
---@return TSNode
local function abs_form_end(node)
   local num_children = node:named_child_count()
   local last_child   = node:named_child(num_children - 1)

   if pred.is_form(node) and last_child then
      ---@cast last_child -nil
      return abs_form_end(last_child)
   else
      return node
   end
end


---@param node TSNode
---@return TSNode
local function abs_form_start(node)
   local first_child = node:named_child(0)
   if first_child then
      return first_child
   else
      return node
   end
end

-----------------------------------------------------------------------------}}}

---@param node TSNode
---@return TSNode
local function prev_element_recr(initial, node)
   local prev = prev_named(node)
   local cond = prev
      and not (prev:type() == "program")
      and not pred.is_form(prev)
      and not pred.is_comment(prev)

   if cond then ---@cast prev -?
      return prev
   elseif prev then
      return prev_element_recr(initial, prev)
   else
      return initial
   end
end


---@param node TSNode
---@param cursor Cursor
---@return TSNode
local function prev_element_from_end(node, cursor)
   local prev = prev_named(node)
   local cond = not cursor:is_behind(node, "start")
      and not pred.is_comment(node)
      and not pred.is_form(node)
      and not (node:type() == "program")

   if cond then
      return node
   elseif prev then
      return prev_element_from_end(prev, cursor)
   else
      return node
   end
end


---@param side "start" | "end"
local function _prev_element(side)
   local cursor, node = Cursor:get()

   if pred.is_form(node) or (node:type() == "program") then
      node = abs_form_end(node)
   end

   return cursor:set(prev_element_from_end(node, cursor), side)
end


function M.prev_element_start()
   return _prev_element("start")
end


function M.prev_element_end()
   return _prev_element("end")
end


--[[ THINKIES;
Aight, what's happening is this: a `program' has no parents or siblings. The
last child is returned (the absolute final form of the program), and it walks
backwards from there.

(As an optimization, feel like we can do some sort of bracketing search, but
that's way down the line.)

Some confusion:
   - Why is the `initial' node not used? I presume it's not finding the intended
     target, and should fall back
   - Why is it not stepping back from the end to find the current node...?

Things to look at:
   - Go back to rev. 19, add some profiling to the `move_to' function. Extra
     counter to see how many jumps it makes before finding the target node.

     My bet is that the previous version of `move_to' is going to take a bunch
     of jumps.

     Yeah lol it's doing about a billion jumps. For a 400 line file it's
     jumping 750 times. Need to use a binary search.
--]]

return M
