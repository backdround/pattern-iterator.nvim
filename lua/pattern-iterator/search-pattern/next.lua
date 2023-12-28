-- require("./utils")
local utils = require(({ ... })[1]:gsub("[^.]+$", "") .. "utils")

---Searches a next pattern match from the given position.
---relative_position is exclusive.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
local search_next = function(pattern, relative_position)
  relative_position.set_cursor()

  local start_pattern_position = utils.vim_search(pattern, "cWn")
  if start_pattern_position == nil then
    return nil
  end

  if start_pattern_position == relative_position then
    start_pattern_position = utils.vim_search(pattern, "Wn")
    if start_pattern_position == nil then
      return nil
    end
  end

  local end_pattern_position = utils.vim_search(pattern, "ecWn")

  while end_pattern_position < start_pattern_position do
    if end_pattern_position == nil then
      return nil
    end
    end_pattern_position.set_cursor()
    end_pattern_position = utils.vim_search(pattern, "eWn")
  end

  return {
    start_position = start_pattern_position,
    end_position = end_pattern_position,
  }
end


---Searches a next pattern match from the given position.
---relative_position is exclusive.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
local next = function(pattern, relative_position)
  local restore_vim_state = utils.prepare_vim_state()

  local result = { search_next(pattern, relative_position) }

  restore_vim_state()
  return unpack(result)
end

return next
