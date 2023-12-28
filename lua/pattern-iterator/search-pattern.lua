-- require("./position/")
local position = require(({ ... })[1]:gsub("[^.]+$", "") .. "position")

---@class PI_PatternPosition
---@field start_position PI_Position
---@field end_position PI_Position

---Vim search wrapper
---@param pattern string
---@param flags string
---@return PI_Position?
local vim_search = function(pattern, flags)
  local found_position = nil
  vim.fn.search(pattern, flags, nil, nil, function()
    found_position = position.from_cursor(true)
  end)

  return found_position
end

---Searches a pattern match that is around the relative_position.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
local search_current = function(pattern, relative_position)
  relative_position.set_cursor()

  local start_pattern_position = vim_search(pattern, "bcWn")
  if start_pattern_position == nil then
    return nil
  end

  start_pattern_position.set_cursor()

  -- Searches the end if the cursor is palced at "$"
  local end_pattern_position = vim_search(pattern, "becWn")

  if start_pattern_position ~= end_pattern_position then
    -- Searches the end in all other cases barring "$"
    end_pattern_position = vim_search(pattern, "ecWn")
  end

  -- Check that the relative_position is in bounds of the found pattern
  if
    start_pattern_position > relative_position
    or end_pattern_position < relative_position
  then
    return nil
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
local search_next = function(pattern, relative_position)
  relative_position.set_cursor()

  local start_pattern_position = vim_search(pattern, "cWn")
  if start_pattern_position == nil then
    return nil
  end

  if start_pattern_position == relative_position then
    start_pattern_position = vim_search(pattern, "Wn")
    if start_pattern_position == nil then
      return nil
    end
  end

  local end_pattern_position = vim_search(pattern, "ecWn")

  while end_pattern_position < start_pattern_position do
    if end_pattern_position == nil then
      return nil
    end
    end_pattern_position.set_cursor()
    end_pattern_position = vim_search(pattern, "eWn")
  end

  return {
    start_position = start_pattern_position,
    end_position = end_pattern_position,
  }
end

---Sets vim state for searching.
---@return function It restores the initial vim state.
local prepare_vim_state = function()
  -- Save the current state
  local saved_position = vim.api.nvim_win_get_cursor(0)
  local saved_virtualedit =
    vim.api.nvim_get_option_value("virtualedit", { scope = "local" })

  -- Set state
  vim.api.nvim_set_option_value( "virtualedit", "onemore", { scope = "local" })

  -- Return restore function
  return function()
    vim.api.nvim_win_set_cursor(0, saved_position)
    vim.api.nvim_set_option_value(
      "virtualedit",
      saved_virtualedit,
      { scope = "local" }
    )
  end
end

local M = {}

---Searches a pattern match that is around the relative_position.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
M.current = function(pattern, relative_position)
  local restore_vim_state = prepare_vim_state()

  local result = { search_current(pattern, relative_position) }

  restore_vim_state()
  return unpack(result)
end

---Searches a next pattern match from the given position.
---relative_position is exclusive.
---@param pattern string
---@param relative_position PI_Position
---@return PI_PatternPosition?
M.next = function(pattern, relative_position)
  local restore_vim_state = prepare_vim_state()

  local result = { search_next(pattern, relative_position) }

  restore_vim_state()
  return unpack(result)
end

return M
