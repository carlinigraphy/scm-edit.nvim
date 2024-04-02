# scm-edit.nvim
Motions that feel good (to me) for editing s-expressions.

Lisps are uniquely poorly suited to the character & line-wise editing model Vim provides.
Tree-sitter allows for a significantly better experience, operating on the nodes that represent the forms/expressions themselves.

This plugin aims to bring more idiomatic vim motions to s-expression traversal & editing.


## Status
Just playin' around.

I have no hope or aspirations that this will ever become more than a pet project.
Learning how to "correctly" structure a Lua nvim plugin.
Maybe mess around with [Fennel](https://fennel-lang.org/).


### Motions
_Completed_ <br/>
- `motions.next_form_start`
- `motions.prev_form_start`
- `motions.next_element_start`
- `motions.prev_element_start`
- `motions.next_element_end`

### Autopairs
_Completed_ <br/>
- `pairs.close_one`
- `pairs.close_all`
- `pairs.toggle`

_Wishlist_ <br/>
- Deleting a paren deletes its match

Switched back to using `nvim-parinfer`, which takes care of paren balancing.
No current need to add any additional functionality here.

### Selecting
(NYI.)

_Wishlist_ <br/>
- Select in form
- Select around form
- Select in definition
- Select around definition

### Editing
(NYI.)

_Wishlist_ <br/>
- Move element, form forwards/backwards/up
- Wrap element, form, visual selection
- Unwrap form
- Slurp/barf


## Inspiration, awe, theft, etc.
- https://github.com/julienvincent/nvim-paredit
- https://github.com/kovisoft/paredit
- https://github.com/gpanders/nvim-parinfer
