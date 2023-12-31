local utils = require(... .. ".utils")

---Represents a position.
---@class PI_Position
---@field line number line
---@field column number virtual column
---@field n_is_pointable boolean position can point to a \n

local M = {}

-- The variable must be file local in order to '__eq' work properly.
-- lua 5.1 checks getmetatable(p1) == getmetatable(p2) before performing the
-- real check.
local position_metatable = {
  __eq = function(p1, p2)
    return p1.line == p2.line and p1.column == p2.column
  end,

  __lt = function(p1, p2)
    if p1.line < p2.line then
      return true
    end

    if p1.line == p2.line and p1.column < p2.column then
      return true
    end

    return false
  end,

  __tostring = function(p)
    return "{ " .. p.line .. ", " .. p.column .. " }"
  end
}

---@param line number line
---@param column number virtual column
---@param n_is_pointable boolean position can point to a \n
---@return PI_Position
local new_position = function(line, column, n_is_pointable)
  ---@class PI_Position
  local p = {
    line = line,
    column = column,
    n_is_pointable = n_is_pointable,
  }

  setmetatable(p, position_metatable)

  ---Sets the cursor to the current position.
  p.set_cursor = function()
    local byte_position = utils.from_virtual_to_byte({ p.line, p.column })
    vim.api.nvim_win_set_cursor(0, byte_position)
  end

  ---Selects a region from the current position to a given position. It works
  ---only for normal or visual mode.
  ---@param position PI_Position
  p.select_region_to = function(position)
    if utils.mode() ~= "visual" and utils.mode() ~= "normal" then
      error("Unable to select region: current mode isn't normal or visual")
    end

    local p1 = M.copy(p)
    local p2 = M.copy(position)

    if p1 > p2 then
      p1, p2 = p2, p1
    end

    local selection = vim.api.nvim_get_option_value("selection", {})
    if selection == "exclusive" then
      p2.move(1)
    end

    -- Use vim.fn.setcharpos instead vim.api.nvim_buf_set_mark, because the
    -- later ignores subsequent <bs>'s.
    vim.fn.setcharpos("'<", { 0, p1.line, p1.column + 1, 0 })
    vim.fn.setcharpos("'>", { 0, p2.line, p2.column + 1, 0 })

    vim.api.nvim_feedkeys("gv", "nx", false)

    if vim.fn.visualmode() ~= "v" and vim.fn.visualmode() ~= "" then
      vim.api.nvim_feedkeys("v", "nx", false)
    end
  end

  ---Performs current operator to the region between the current and the given point.
  ---@param position PI_Position
  p.perform_operator_to = function(position)
    if utils.mode() ~= "operator-pending" then
      error("Unable to perform operator: current mode isn't operator pending")
    end

    local p1 = M.copy(p)
    local p2 = M.copy(position)

    if p1 > p2 then
      p1, p2 = p2, p1
    end

    -- Use vim.fn.setcharpos instead vim.api.nvim_buf_set_mark, because the
    -- later ignores subsequent <bs>'s.
    vim.fn.setcharpos("'<", { 0, p1.line, p1.column + 1, 0 })
    vim.fn.setcharpos("'>", { 0, p2.line, p2.column + 1, 0 })

    vim.api.nvim_feedkeys("gv", "nx", false)

    if vim.fn.visualmode() ~= "v" and vim.fn.visualmode() ~= "" then
      vim.api.nvim_feedkeys("v", "nx", false)
    end
  end

  ---Sets new n_is_pointable
  ---@param new_n_is_pointable boolean
  p.set_n_is_pointable = function(new_n_is_pointable)
    local line_length = utils.virtual_line_length(p.line, new_n_is_pointable)
    if new_n_is_pointable == false and p.column == line_length then
      -- Correct column
      p.column = math.max(1, line_length - 1)
    end

    p.n_is_pointable = new_n_is_pointable
  end

  local move_forward = function(offset)
    local last_line = vim.api.nvim_buf_line_count(0)
    while true do
      local line_length = utils.virtual_line_length(p.line, p.n_is_pointable)
      local available_places_on_line = (line_length - 1) - p.column

      if available_places_on_line >= offset then
        p.column = p.column + offset
        return
      end

      if p.line == last_line then
        p.column = line_length - 1
        return
      end

      p.column = 0
      p.line = p.line + 1
      offset = offset - (available_places_on_line + 1)
    end
  end

  local move_backward = function(offset)
    while true do
      if p.column >= offset then
        p.column = p.column - offset
        return
      end

      if p.line == 1 then
        p.column = 0
        return
      end

      offset = offset - (p.column + 1)
      p.line = p.line - 1
      local line_length = utils.virtual_line_length(p.line, p.n_is_pointable)
      p.column = line_length - 1
    end
  end

  ---Moves the position according to the offset. If offset > 0 then it moves
  ---forward else backward.
  ---@param offset number
  p.move = function(offset)
    if offset > 0 then
      move_forward(offset)
    else
      move_backward(math.abs(offset))
    end
  end

  return p
end

---Creates PI_Position from the position of the current cursor.
---@param n_is_pointable boolean position can point to a \n
---@return PI_Position
M.from_cursor = function(n_is_pointable)
  if n_is_pointable == nil then
    n_is_pointable = false
  end

  local byte_position = vim.api.nvim_win_get_cursor(0)
  local position = utils.from_byte_to_virtual(byte_position)
  position = utils.place_in_bounds(position, n_is_pointable)
  return new_position(position[1], position[2], n_is_pointable)
end

---Creates PI_Position from the given virtual position.
---@param line number virtual line
---@param column number virtual column
---@param n_is_pointable? boolean position can point to a \n
M.from_coordinates = function(line, column, n_is_pointable)
  if n_is_pointable == nil then
    n_is_pointable = false
  end

  if type(line) ~= "number" or type(column) ~= "number" then
    error("Line and column must be numbers")
  end

  local coordinates = utils.place_in_bounds({ line, column }, n_is_pointable)
  return new_position(coordinates[1], coordinates[2], n_is_pointable)
end

---Creates PI_Position from an existing PI_Position
---@param p PI_Position
---@return PI_Position
M.copy = function(p)
  return new_position(p.line, p.column, p.n_is_pointable)
end

return M
