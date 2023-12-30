# Pattern-iterator.nvim

It's a Neovim plugin that provides an iterator over vim-pattern matches
in the buffer text.

## Usage example
```lua
local pattern_iterator = require("pattern-iterator")

local function place_cursor_to_end_of_lower_word()
  local lower_word_pattern = "\\v[[:lower:]]+"

  local iterator = pattern_iterator.new_around(lower_word_pattern, {})
    or pattern_iterator.new_forward(lower_word_pattern, {})

  if iterator == nil then
    return
  end

  iterator.end_position().set_cursor()
end
```


## API

### Module
Function | Return type | Description
-- | -- | --
new_around(pattern,options) | PI_Iterator? | Creates an iterator that points to a current match at the given position or the cursor. Returns nil if there is no pattern at the position.
new_forward(pattern,options) | PI_Iterator? | Creates an iterator that points to a match after the given position or the cursor. Returns nil if there is no pattern after the position.
new_backward(pattern,options) | PI_Iterator? | Creates an iterator that points to a match before the given position or the cursor. Returns nil if there is no pattern before the position.

```lua
local options = {
  -- Base position to search from.
  -- If nil then it uses the cursor position.
  from_search_position = { 2, 6 },
  -- Used to indicate if the end of the line `\n` is pointable.
  -- If nil then it calculates based on the current mode (mode ~= "normal").
  n_is_pointable = true,
}
```

### PI_Iterator
Method | Return type | Description
-- | -- | --
next(count) | boolean | Advances the iterator forward to the count of matches. Returned boolean indicates that the iterator hasn't stuck on the last match yet.
previous(count) | boolean | Advances the iterator backward to the count of matches. Returned boolean indicates that the iterator hasn't stuck on the first match yet.
start_position() | PI_Position | The start position of the current match.
end_position() | PI_Position | The end position of the current match.

### PI_Position

Method / Member | Return type | Description
-- | -- | --
set_cursor() | - | Sets the cursor to the position.
select_region_to(position) | - | Selects the region between to another position.
move(offset) | - | Moves the position according to the offset. If offset > 0 then it moves forward else backward.
set_n_is_pointable(n_is_pointable) | - | Sets the flag that indicates that the position can point to the `\n`.
line | number | Position's line.
column | number | Position's virtual column.
n_is_pointable | boolean | The flag that indicates that the position can point to the `\n`.
