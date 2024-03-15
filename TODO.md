# TODO

## Contextual movement
Repeated movements should stay within the same context.
"Big movements" should either
    * stay within contextual boundaries, or
    * jump over intermediate contexts to the next match.

## Relative positions
May be useful to have predicates w/ cursor relative to a node, and node
relative to the cursor.
They would be slightly different.

Cursor:
  - `before_node_start`
  - `before_node_end`
  - `after_node_start`
  - `after_node_end`

Node:
    - `before_cursor`
      - i.e., `after_node_end`
    - `after_cursor`
      - i.e., `before_node_start`


<!---
  vim: sw=2 ts=2 sts=2
-->
