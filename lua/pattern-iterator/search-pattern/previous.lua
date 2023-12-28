-- require("./utils")
local utils = require(({ ... })[1]:gsub("[^.]+$", "") .. "utils")

---Searches a previous pattern match from the given position.
---relative_position is exclusive.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
local search_previous = function(pattern, relative_position)
  relative_position.set_cursor()

  local offset = 1
  local end_pattern_position = nil
  while true do
    local potential_end_pattern_position = utils.vim_search(pattern, "beWn")
    if potential_end_pattern_position == nil then
      return nil
    end

    if relative_position ~= potential_end_pattern_position then
      end_pattern_position = potential_end_pattern_position
      break
    end

    potential_end_pattern_position.move(-offset)
    potential_end_pattern_position.set_cursor()
  end

  end_pattern_position.set_cursor()
  local start_pattern_position = utils.vim_search(pattern, "bcWn")

  return {
    start_position = start_pattern_position,
    end_position = end_pattern_position,
  }
end

---Searches a previous pattern match from the given position.
---relative_position is exclusive.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
local previous = function(pattern, relative_position)
  local restore_vim_state = utils.prepare_vim_state()

  local result = { search_previous(pattern, relative_position) }

  restore_vim_state()
  return unpack(result)
end

return previous
