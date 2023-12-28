local h = require("tests.helpers")
local search_pattern = require("pattern-iterator.search-pattern")
local position = require("pattern-iterator.position")

require("tests.custom-asserts").register()

describe("search-pattern.next", function()
  -- The case isn't possible because of vim.fn.search
  -- https://github.com/vim/vim/issues/13755#issuecomment-1869227510
  pending("pattern == 'a$'")
  -- The case isn't possible because of vim.fn.search
  pending("pattern == '(a|$)'")

  it("there is no next pattern", function()
    h.get_preset("<b> <b> <b>")()

    local from_position = position.from_coordinates(1, 0)
    local pattern_position = search_pattern.next("\\M<a>", from_position)

    assert.is.Nil(pattern_position)
  end)

  describe("simple pattern", function()
    before_each(h.get_preset("<a> <a> <a>"))
    local pattern = "\\M<a>"

    it("from a position that is before a pattern", function()
      local from_position = position.from_coordinates(1, 3)
      local pattern_position = search_pattern.next(pattern, from_position)

      assert.pattern_position(pattern_position, { 1, 4 }, { 1, 6 })
    end)

    it("from a position that is at the start of a previous match", function()
      local from_position = position.from_coordinates(1, 0)
      local pattern_position = search_pattern.next(pattern, from_position)

      assert.pattern_position(pattern_position, { 1, 4 }, { 1, 6 })
    end)

    it("from a position that is in the middle of a previous match", function()
      local from_position = position.from_coordinates(1, 1)
      local pattern_position = search_pattern.next(pattern, from_position)

      assert.pattern_position(pattern_position, { 1, 4 }, { 1, 6 })
    end)

    it("from a position that is at the end of a previous match", function()
      local from_position = position.from_coordinates(1, 2)
      local pattern_position = search_pattern.next(pattern, from_position)

      assert.pattern_position(pattern_position, { 1, 4 }, { 1, 6 })
    end)
  end)

  describe("muliline pattern", function()
    before_each(h.get_preset([[
      abba
      abbba
      abba
    ]]))

    describe("pattern == '$'", function()
      it("from a position that is before the pattern", function()
        local from_position = position.from_coordinates(2, 4)
        local pattern_position = search_pattern.next("\\v$", from_position)

        assert.pattern_position(pattern_position, { 2, 5 }, { 2, 5 })
      end)

      it("from a position that is at the pattern", function()
        local from_position = position.from_coordinates(1, 4, true)
        local pattern_position = search_pattern.next("\\v$", from_position)

        assert.pattern_position(pattern_position, { 2, 5 }, { 2, 5 })
      end)
    end)

    describe("pattern == '^'", function()
      it("from a position that is before the pattern", function()
        local from_position = position.from_coordinates(1, 4, true)
        local pattern_position = search_pattern.next("\\v^", from_position)

        assert.pattern_position(pattern_position, { 2, 0 }, { 2, 0 })
      end)

      it("from a position that is on the pattern", function()
        local from_position = position.from_coordinates(2, 0, true)
        local pattern_position = search_pattern.next("\\v^", from_position)

        assert.pattern_position(pattern_position, { 3, 0 }, { 3, 0 })
      end)
    end)

    describe("pattern == 'a\\na'", function()
      it("from a position that is before the pattern", function()
        local from_position = position.from_coordinates(1, 2, true)
        local pattern_position = search_pattern.next("\\va\\na", from_position)

        assert.pattern_position(pattern_position, { 1, 3 }, { 2, 0 })
      end)

      it("from a position that is on the pattern", function()
        local from_position = position.from_coordinates(1, 3, true)
        local pattern_position = search_pattern.next("\\va\\na", from_position)

        assert.pattern_position(pattern_position, { 2, 4 }, { 3, 0 })
      end)
    end)
  end)
end)
