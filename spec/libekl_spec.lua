require "spec.setup"

describe("LibEKL Mock Functions", function()

  describe("LibEKL.Tools.Math.Round", function()
    it("should round to 2 decimal places", function()
      assert.are.equal(1.57, LibEKL.Tools.Math.Round(1.567, 2))
    end)

    it("should round to 0 decimal places by default", function()
      assert.are.equal(2, LibEKL.Tools.Math.Round(1.567))
    end)

    it("should handle negative numbers", function()
      assert.are.equal(-1.57, LibEKL.Tools.Math.Round(-1.567, 2))
    end)
  end)

  describe("LibEKL.Tools.Color.RGBToHex", function()
    it("should convert RGB to hex color", function()
      assert.are.equal("FF6A00", LibEKL.Tools.Color.RGBToHex(255, 106, 0))
    end)

    it("should convert black to hex", function()
      assert.are.equal("000000", LibEKL.Tools.Color.RGBToHex(0, 0, 0))
    end)

    it("should convert white to hex", function()
      assert.are.equal("FFFFFF", LibEKL.Tools.Color.RGBToHex(255, 255, 255))
    end)
  end)

  describe("LibEKL.strings.split", function()
    it("should split string by delimiter", function()
      local result = LibEKL.strings.split("a,b,c", ",")
      assert.are.equal(3, #result)
      assert.are.equal("a", result[1])
      assert.are.equal("b", result[2])
      assert.are.equal("c", result[3])
    end)

    it("should handle single element", function()
      local result = LibEKL.strings.split("hello", ",")
      assert.are.equal(1, #result)
      assert.are.equal("hello", result[1])
    end)
  end)

  describe("LibEKL.strings.trim", function()
    it("should remove leading and trailing whitespace", function()
      assert.are.equal("hello", LibEKL.strings.trim("  hello  "))
    end)

    it("should handle no whitespace", function()
      assert.are.equal("hello", LibEKL.strings.trim("hello"))
    end)
  end)

  describe("LibEKL.Tools.Table.IsMember", function()
    it("should find member in table", function()
      local tbl = {1, 2, 3}
      assert.is_true(LibEKL.Tools.Table.IsMember(tbl, 2))
    end)

    it("should return false for non-member", function()
      local tbl = {1, 2, 3}
      assert.is_false(LibEKL.Tools.Table.IsMember(tbl, 4))
    end)
  end)

  describe("LibEKL.Tools.Table.Copy", function()
    it("should deep copy a table", function()
      local original = {a = 1, b = {c = 2}}
      local copy = LibEKL.Tools.Table.Copy(original)

      assert.are.equal(original.a, copy.a)
      assert.are.equal(original.b.c, copy.b.c)
      assert.is_not.equal(original.b, copy.b)
    end)
  end)

  describe("LibEKL.Tools.Settings.UpdateSettings", function()
    it("should merge default settings into target", function()
      local defaults = { activate = true, x = 0, y = 0 }
      local target = { activate = false }

      LibEKL.Tools.Settings.UpdateSettings(defaults, target)

      assert.are.equal(false, target.activate)
      assert.are.equal(0, target.x)
      assert.are.equal(0, target.y)
    end)

    it("should handle nested tables", function()
      local defaults = { modules = { chat = { enable = true } } }
      local target = { modules = {} }

      LibEKL.Tools.Settings.UpdateSettings(defaults, target)

      assert.are.equal(true, target.modules.chat.enable)
    end)
  end)

  describe("LibEKL.Unit.GetPlayerDetails", function()
    it("should return player details table", function()
      local player = LibEKL.Unit.GetPlayerDetails()

      assert.is_not_nil(player.id)
      assert.is_not_nil(player.name)
      assert.is_not_nil(player.level)
    end)
  end)

end)
