--------------------------------------------------------------------------------
-- internals
--------------------------------------------------------------------------------

local pred    = require("scm-edit.predicates")
local Cursor  = require("scm-edit.cursor")

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
         return node:next_named_sibling()
      end
      node = node:parent() --[[ @as TSNode ]]
   until not node:parent()
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

   local prev = node:prev_named_sibling()
   ---@cast prev -nil

   -- `nil check` implicitly covered by the conditional.
   ---@diagnostic disable-next-line: need-check-nil
   while prev:named_child_count() > 0 do
      prev = prev:named_child(prev:named_child_count() - 1)
   end

   return prev
end


-- TODO;
-- Can likely merge with `next_named`.
--
---@param node TSNode
---@return TSNode?
--
-- Utility function to return the next node, without recursing into child nodes
-- as in `next_named`.
local function next_named_up(node)
   local parent = node:parent()
   local next = node:next_named_sibling()

   if next then
      return next
   elseif parent then
      return next_named_up(parent)
   end
end


---@param form    TSNode
---@param cursor  Cursor
---@param min     integer
---@param max     integer
---@param closest integer  Index of TSNode after Cursor
---@return TSNode
--
-- Regardless of subsequent jump direction, only returns the index of the node
-- *after* the cursor.
--
-- ## Jumping backwards
-- Starting one node ahead reduces the risk of overshooting the target node, and
-- adds very few additional jumps. Easier to reason about; makes it worth it.
--
-- ## Jumping forwards
-- Starting on the subsequent node obviously makes sense. Either doesn't
-- require a jump at all, or very few to reach the target.
local function _bracket(form, cursor, min, max, closest)
   if max - min == 1 then
      return form:named_child(closest) --[[ @as TSNode ]]
   end

   ---@type integer
   local pivot = min + math.floor((max - min) / 2)
   local test  = form:named_child(pivot) --[[ @cast test -nil ]]

   if cursor:is_behind(test, "start") then
      return _bracket(form, cursor, min, pivot, pivot)
   else
      return _bracket(form, cursor, pivot, max, closest)
   end
end


---@param form   TSNode
---@param cursor Cursor
---@return TSNode?
local function bracket(form, cursor)
   assert(pred.is_form(form))

   local max   = form:named_child_count() - 1
   local first = form:named_child(0)
   local last  = form:named_child(max)

   ---@cast last -nil
   -- Covered by initial check. If there's a first child, there' also a last
   -- child. Not sure if there's a better way of annotating this below.

   -- Edge case #1;  empty list, nothing to seek for
   if not first then
      return next_named_up(form)

   -- Edge case #2;  cursor past the last element
   -- (most often on the closing paren)
   elseif cursor:is_ahead(last, "end") then
      return next_named_up(form)

   -- Edge case #3;  cursor before the first element
   -- (most often on the opening paren)
   elseif cursor:is_behind(first, "start") then
      return first

   -- Normal case;  cursor on whitespace within a form
   else
      return _bracket(form, cursor, 0, max, max)
   end
end


---@param node TSNode?
---@param cursor Cursor
---@param step_fn fun(node: TSNode): TSNode?
---@param predicate fun(node: TSNode, cursor: Cursor): boolean
---@return TSNode?
local function seek_until(node, cursor, step_fn, predicate)
   if not node then
      return
   elseif predicate(node, cursor) then
      return node
   else
      return seek_until(step_fn(node), cursor, step_fn, predicate)
   end
end


-- TODO; this can probably be rolled into `prev_element`.
--
---@param side "start" | "end"
local function prev_element(side)
   local cursor, node = Cursor:get()

   ---@type TSNode?
   local prev = node

   if pred.is_form(node) then
      prev = bracket(node, cursor)
   end

   prev = seek_until(prev, cursor, prev_named, function(n, c)
      return n
         and not pred.is_form(n)
         and not pred.is_comment(n)
         and c:is_ahead(n, side)
   end)

   if prev then
      cursor:set(prev, side)
   end
end


-- TODO; this can probably be rolled into `prev_element`.
--
---@param side "start" | "end"
local function next_element(side)
   local cursor, node = Cursor:get()

   ---@type TSNode?
   local next = node

   if pred.is_form(node) then
      next = bracket(node, cursor)
   end

   next = seek_until(next, cursor, next_named, function(n, c)
      return n
         and not pred.is_form(n)
         and not pred.is_comment(n)
         and c:is_behind(n, side)
   end)

   if next then
      cursor:set(next, side)
   end
end


local function prev_form(side)
   local cursor, node = Cursor:get()

   ---@type TSNode?
   local prev = node

   if pred.is_form(node) then
      prev = bracket(node, cursor)
   end

   prev = seek_until(prev, cursor, prev_named, function(n, c)
      return n
         and pred.is_form(n)
         and c:is_ahead(n, side)
   end)

   if prev then
      cursor:set(prev, side)
   end
end


local function next_form(side)
   local cursor, node = Cursor:get()

   ---@type TSNode?
   local next = node

   if pred.is_form(node) then
      next = bracket(node, cursor)
   end

   next = seek_until(next, cursor, next_named, function(n, c)
      return n
         and pred.is_form(n)
         and c:is_behind(n, side)
   end)

   if next then
      cursor:set(next, side)
   end
end


---@param count integer
---@param fn fun(any)
---@vararg any
local function with_count(count, fn, ...)
   repeat fn(...)
      print(count)
      count = count - 1
   until
      count == 0
end


--------------------------------------------------------------------------------
-- externals
--------------------------------------------------------------------------------
local M = {}


function M.prev_element_start()
   with_count(vim.v.count1, prev_element, "start")
end


function M.prev_element_end()
   with_count(vim.v.count1, prev_element, "end")
end


function M.prev_form_start()
   local count = vim.v.count1
   vim.cmd[[ normal! m' ]]
   with_count(count, prev_form, "start")
end


function M.next_element_start()
   with_count(vim.v.count1, next_element, "start")
end


function M.next_element_end()
   with_count(vim.v.count1, next_element, "end")
end


function M.next_form_start()
   local count = vim.v.count1
   vim.cmd[[ normal! m' ]]
   with_count(count, next_form, "start")
end


return M
