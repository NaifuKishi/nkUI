# Testing Quick Start

## 1. Install Dependencies

### Option A: Automatic (Linux/macOS)
```bash
./setup-testing.sh
```

### Option B: Manual
You need:
- **Lua 5.1+** (https://www.lua.org/download.html)
- **Busted** (required for testing)
- **LuaCov** (optional, for coverage reports)

Then:
```bash
# Required
luarocks install busted

# Optional (for coverage reports)
luarocks install luacov
```

## 2. Run Tests

```bash
# Run all tests (default)
busted

# Verbose output
busted --verbose

# With coverage report (requires luarocks install luacov)
busted --coverage
```

## 3. View Results

Tests pass? Great! 🎉

```
28 tests, 0 failures
```

## 4. Add Your Own Tests

Create `spec/mymodule_spec.lua`:

```lua
require "spec.setup"

describe("My Module", function()
  it("should do something", function()
    assert.is_true(true)
  end)
end)
```

Run:
```bash
busted spec/mymodule_spec.lua
```

## Common Issues

### "command not found: busted"
Install LuaRocks and Busted: Run `./setup-testing.sh` or see TESTING.md

### "cannot open `spec/setup.lua`"
Make sure you're in the nkUI directory: `cd /path/to/nkUI`

### Tests fail with "undefined global"
Add mocks to `spec/setup.lua` for missing Rift APIs

## Next Steps

- See **TESTING.md** for comprehensive guide
- Check **spec/** directory for example tests
- Read **CLAUDE.md** for nkUI code patterns

## Structure

```
nkUI/
├── spec/
│   ├── setup.lua              ← Mocks and shared setup
│   ├── main_spec.lua          ← Example: Main namespace
│   ├── libekl_spec.lua        ← Example: LibEKL utilities
│   └── tools_spec.lua         ← Example: Tools module
├── .busted                    ← Busted configuration
├── .luacov                    ← Coverage configuration
├── TESTING.md                 ← Full guide
└── setup-testing.sh           ← Installation script
```

---

**Questions?** See TESTING.md for detailed documentation.
