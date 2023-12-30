local h = require("tests.helpers")
local position = require("pattern-iterator.position")

require("tests.custom-asserts").register()

describe("position", function()
  before_each(h.get_preset([[
    some
    words
    here
  ]]))

  describe("create", function()
    describe("from the cursor", function()
      it("in bounds", function()
        h.set_cursor(2, 1)
        local p = position.from_cursor(true)
        assert.position(p, { 2, 1, true })
      end)

      it("on the end of a line with n_is_pointable == false", function()
        h.trigger_visual()

        h.set_cursor(2, 5)
        local p = position.from_cursor(false)

        assert.position(p, { 2, 4, false })
      end)

      it("on the end of a line with n_is_pointable == true", function()
        h.trigger_visual()

        h.set_cursor(2, 5)
        local p = position.from_cursor(true)

        assert.position(p, { 2, 5, true })
      end)
    end)

    describe("from given coordinates", function()
      it("in bounds", function()
        local p = position.from_coordinates(2, 3, true)
        assert.position(p, { 2, 3, true })
      end)

      it("on the end of a line with n_is_pointable == false", function()
        local p = position.from_coordinates(2, 5, false)
        assert.position(p, { 2, 4, false })
      end)

      it("on the end of a line with n_is_pointable == true", function()
        local p = position.from_coordinates(2, 5, true)
        assert.position(p, { 2, 5, true })
      end)

      it("out of bounds", function()
        local p = position.from_coordinates(-1, 5, true)
        assert.position(p, { 1, 0, true })

        p = position.from_coordinates(4, 5, true)
        assert.position(p, { 3, 4, true })

        p = position.from_coordinates(2, -2, true)
        assert.position(p, { 2, 0, true })

        p = position.from_coordinates(2, 20, true)
        assert.position(p, { 2, 5, true })
      end)
    end)

    it("by copy", function()
      local p1 = position.from_coordinates(2, 3, true)
      local p2 = position.copy(p1)
      p1.move(1)

      assert.position(p2, { 2, 3, true })
    end)
  end)

  describe("move", function()
    it("forward", function()
      local p = position.from_coordinates(2, 3, true)
      p.move(1)

      assert.position(p, { 2, 4, true })
    end)

    it("backward", function()
      local p = position.from_coordinates(2, 3, true)
      p.move(-1)

      assert.position(p, { 2, 2, true })
    end)

    it("on next line", function()
      local p = position.from_coordinates(2, 4, true)
      p.move(2)

      assert.position(p, { 3, 0, true })
    end)

    it("on previous line", function()
      local p = position.from_coordinates(2, 2, true)
      p.move(-4)

      assert.position(p, { 1, 3, true })
    end)

    it("through an empty line forward", function()
      h.get_preset([[
        some

        here
      ]])()

      local p = position.from_coordinates(1, 2, false)
      p.move(4)

      assert.position(p, { 3, 1, false })
    end)

    it("through an empty line backward", function()
      h.get_preset([[
        some

        here
      ]])()

      local p = position.from_coordinates(3, 1, false)
      p.move(-4)

      assert.position(p, { 1, 2, false })
    end)

    it("stuck against the end of the buffer", function()
      local p = position.from_coordinates(3, 0, false)
      p.move(4)

      assert.position(p, { 3, 3, false })
    end)

    it("stuck against the start of the buffer", function()
      local p = position.from_coordinates(1, 3, false)
      p.move(-4)

      assert.position(p, { 1, 0, false })
    end)
  end)

  describe("compare", function()
    it("less", function()
      local p1 = position.from_coordinates(2, 3, false)
      local p2 = position.from_coordinates(2, 4, false)
      assert.is.True(p1 < p2)
    end)

    it("not less", function()
      local p1 = position.from_coordinates(2, 4, false)
      local p2 = position.from_coordinates(2, 3, false)
      assert.is.Not.True(p1 < p2)
    end)

    it("equal", function()
      local p1 = position.from_coordinates(2, 3, false)
      local p2 = position.from_coordinates(2, 3, false)
      assert.is.True(p1 == p2)
    end)

    it("not equal", function()
      local p1 = position.from_coordinates(2, 3, false)
      local p2 = position.from_coordinates(2, 4, false)
      assert.is.Not.True(p1 == p2)
    end)
  end)

  describe("act", function()
    it("set_n_is_pointable", function()
      local p = position.from_coordinates(2, 5, true)
      assert.position(p, { 2, 5, true })

      p.set_n_is_pointable(false)
      assert.position(p, { 2, 4, false })

      p.move(1)
      assert.position(p, { 3, 0, false })

      p.set_n_is_pointable(true)
      p.move(-1)
      assert.position(p, { 2, 5, true })
    end)

    describe("select_region_to", function()
      it("forward", function()
        local p1 = position.from_coordinates(1, 3, false)
        local p2 = position.from_coordinates(2, 4, false)
        p1.select_region_to(p2)
        assert.selected_region({ 1, 3 }, { 2, 4 })
      end)

      it("backward", function()
        local p1 = position.from_coordinates(1, 3, false)
        local p2 = position.from_coordinates(2, 4, false)
        p2.select_region_to(p1)
        assert.selected_region({ 1, 3 }, { 2, 4 })
      end)

      it("with 'selection' == 'exclusive'", function()
        vim.go.selection = "exclusive"

        local p1 = position.from_coordinates(1, 3, false)
        local p2 = position.from_coordinates(2, 2, false)
        p1.select_region_to(p2)

        h.feedkeys("d", true)

        assert.buffer([[
          somds
          here
        ]])
      end)

      describe("in operator-pending mode after", function()
        local delete_through_keymap_to = function(line, column)
          h.trigger_delete()

          h.perform_through_keymap(function()
            local cursor = position.from_cursor(true)
            local p = position.from_coordinates(line, column, true)
            cursor.select_region_to(p)
          end, true)
        end

        it("after none visual selection", function()
          delete_through_keymap_to(3, 1)
          assert.buffer("re")
        end)

        it("after linewise visual selection", function()
          h.feedkeys("V<esc>", true)

          delete_through_keymap_to(3, 1)
          assert.buffer("re")
        end)

        it("after charwise visual selection", function()
          h.feedkeys("v<esc>", true)

          delete_through_keymap_to(3, 1)
          assert.buffer("re")
        end)

        it("after blockwise visual selection", function()
          h.feedkeys("<C-v><esc>", true)

          delete_through_keymap_to(3, 1)
          assert.buffer("re")
        end)
      end)
    end)

    describe("set_cursor", function()
      it("in normal mode", function()
        h.set_cursor(1, 0)
        local p = position.from_coordinates(2, 3, false)
        p.set_cursor()
        assert.cursor_at(2, 3)
      end)

      it("in normal mode to the end of a line", function()
        h.set_cursor(1, 0)
        local p = position.from_coordinates(2, 5, true)
        p.set_cursor()
        assert.cursor_at(2, 4)
      end)

      it("in visual mode", function()
        h.set_cursor(1, 2)

        h.trigger_visual()
        local p = position.from_coordinates(2, 3, true)
        p.set_cursor()

        assert.selected_region({ 1, 2 }, { 2, 3 })
      end)

      it("in visual mode to the end of a line", function()
        h.set_cursor(1, 2)

        h.trigger_visual()
        local p = position.from_coordinates(2, 5, true)
        p.set_cursor()

        assert.selected_region({ 1, 2 }, { 2, 5 })
      end)

      it("in operator-pending mode", function()
        h.trigger_delete()

        h.perform_through_keymap(function()
          local p = position.from_coordinates(3, 0, true)
          p.set_cursor()
        end, true)

        assert.buffer("here")
      end)

      it("in insert mode", function()
        h.trigger_insert()

        h.perform_through_keymap(function()
          local p = position.from_coordinates(3, 1, true)
          p.set_cursor()
        end, true)

        assert.cursor_at(3, 0)
      end)
    end)
  end)
end)
