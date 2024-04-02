--------------------------------------------------------------------------------
-- internals
--------------------------------------------------------------------------------
local pred   = require("scm-edit.predicates")
local Cursor = require("scm-edit.cursor")

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
--
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


---@param direction "prev" | "next"
---@param side "start" | "end"
---@param predicate fun(node: TSNode, cursor: Cursor): boolean
--
---@return nil
local function jump_to(direction, side, predicate)
   local cursor, node = Cursor:get()

   ---@type TSNode?
   local target = node

   if pred.is_form(node) then
      target = bracket(node, cursor)
   end

   local step_fn
   if direction == "prev" then
      step_fn = prev_named
   elseif direction == "next" then
      step_fn = next_named
   else
      error("direction must be one of ['prev', 'next']", 2)
   end

   target = seek_until(target, cursor, step_fn, predicate)

   if target then
      cursor:set(target, side)
   end
end


---@param count integer
---@param fn fun()
local function with_count(count, fn)
   repeat fn()
      count = count - 1
   until
      count == 0
end


--------------------------------------------------------------------------------
-- externals
--------------------------------------------------------------------------------
local M = {}


function M.prev_element_start()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[b]]
   end

   with_count(vim.v.count1, function()
      jump_to("prev", "start", function(node, cursor)
         return node
            and not pred.is_form(node)
            and not pred.is_comment(node)
            and cursor:is_ahead(node, "start")
      end)
   end)
end


function M.prev_element_end()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[ge]]
   end

   with_count(vim.v.count1, function()
      jump_to("prev", "end", function(node, cursor)
         return node
            and not pred.is_form(node)
            and not pred.is_comment(node)
            and cursor:is_ahead(node, "end")
      end)
   end)
end


function M.prev_form_start()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[B]]
   end

   local count = vim.v.count1
   vim.cmd[[normal! m']]

   with_count(count, function()
      jump_to("prev", "start", function(node, cursor)
         return node
            and pred.is_form(node)
            and cursor:is_ahead(node, "start")
      end)
   end)
end


function M.next_element_start()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[w]]
   end

   with_count(vim.v.count1, function()
      jump_to("next", "start", function(node, cursor)
         return node
            and not pred.is_form(node)
            and not pred.is_comment(node)
            and cursor:is_behind(node, "start")
      end)
   end)
end


function M.next_element_end()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[e]]
   end

   with_count(vim.v.count1, function()
      jump_to("next", "end", function(node, cursor)
         return node
            and not pred.is_form(node)
            and not pred.is_comment(node)
            and cursor:is_behind(node, "end")
      end)
   end)
end


function M.next_form_start()
   if not pred.is_code(Cursor.get_node()) then
      return vim.cmd[[W]]
   end

   local count = vim.v.count1
   vim.cmd[[normal! m']]

   with_count(count, function()
      jump_to("next", "start", function(node, cursor)
         return node
            and pred.is_form(node)
            and cursor:is_behind(node, "start")
      end)
   end)
end


return M
