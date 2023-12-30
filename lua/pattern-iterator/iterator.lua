local position = require(({ ... })[1]:gsub("[^.]+$", "") .. "position")
local search_pattern = require(({ ... })[1]:gsub("[^.]+$", "") .. "search-pattern")

---Pattern iterator represents positions of the current match.
---@class PI_Iterator
---@field start_position PI_Position Start of the current match
---@field end_position PI_Position End of the current match
---@field _pattern string
---@field _base_match PI_Match
---@field _n_is_pointable boolean

---@param pattern string
---@param base_match PI_Match
---@param n_is_pointable boolean positions can point to a \n.
---@return PI_Iterator
local new = function(pattern, base_match, n_is_pointable)
  local i = {
    _pattern = pattern,
    _current_match = base_match,
    _n_is_pointable = n_is_pointable,
  }

  ---Returns the start position of the match
  ---@return PI_Position
  i.start_position = function()
    local p = position.copy(i._current_match.start_position)
    p.set_n_is_pointable(i._n_is_pointable)
    return p
  end

  ---Returns the end position of the match
  ---@return PI_Position
  i.end_position = function()
    local p = position.copy(i._current_match.end_position)
    p.set_n_is_pointable(i._n_is_pointable)
    return p
  end

  ---@param count? number count of matches to advance
  ---@return boolean performed without hitting the last match
  i.next = function(count)
    count = count or 1

    for _ = 1, count do
      local next_match =
        search_pattern.next(i._pattern, i._current_match.end_position)

      if next_match == nil then
        return false
      end

      i._current_match = next_match
    end

    return true
  end

  ---@param count? number count of matches to advance
  ---@return boolean performed without hitting the fisrt match
  i.previous = function(count)
    count = count or 1

    for _ = 1, count do
      local previous_match =
        search_pattern.previous(i._pattern, i._current_match.end_position)

      if previous_match == nil then
        return false
      end

      i._current_match = previous_match
    end

    return true
  end

  return i
end

return {
  new = new
}
