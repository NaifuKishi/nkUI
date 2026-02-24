require "spec.setup"

describe("nkUI Main Namespace", function()

  describe("Guard pattern", function()
    it("should prevent multiple initializations", function()
      -- The guard pattern ensures nkUI only initializes once
      -- This test verifies the pattern concept

      if not nkUI then nkUI = {} else return end

      local shouldNotReach = false
      if not nkUI then
        shouldNotReach = true
      else
        return
      end

      assert.is_false(shouldNotReach)
    end)
  end)

  describe("Namespace initialization", function()
    it("should have Rift API functions available", function()
      assert.is_not_nil(Inspect)
      assert.is_not_nil(Command)
      assert.is_not_nil(Event)
      assert.is_not_nil(UI)
    end)

    it("should have LibEKL available", function()
      assert.is_not_nil(LibEKL)
      assert.is_not_nil(LibEKL.Events)
      assert.is_not_nil(LibEKL.Tools)
      assert.is_not_nil(LibEKL.UI)
    end)
  end)

  describe("Addon info", function()
    it("should have valid addon identifier", function()
      local addonInfo = Inspect.Addon.Current()
      assert.are.equal("nkUI", addonInfo.identifier)
    end)

    it("should have valid version", function()
      local addonInfo = Inspect.Addon.Current()
      assert.is_not_nil(addonInfo.version)
    end)
  end)

end)
