<!---
  vim: sw=2 ts=2 sts=2
-->

# TODO

## Contextual movement
Repeated movements should stay within the same context.
"Big movements" should either
    * stay within contextual boundaries, or
    * jump over intermediate contexts to the next match.

### 2024-03-27
As expected, my opinions have changed as I've actually used the plugin to edit code.

I'm starting to once again think this is a good idea.
Though the editing model must be extraordinarily simple.

When in a non-code context, motions use default mappings.
When in a code context, can use w/W/b/B/e for moving about forms / elements.


## Bugs
- [ ] If after the opening `(` of the final form of a program, motions in both directions do not work
      - Seemingly catching the early return here
