# nkUI Testing Guide

This document describes the testing setup for nkUI using Busted.

## Setup

### Prerequisites

- **Lua 5.1** (required by Rift)
- **Busted** – BDD testing framework for Lua (required)
- **LuaCov** – Code coverage tool (optional)

### Installation

#### Using LuaRocks (recommended)

```bash
# Install Busted (required)
luarocks install busted

# Optionally install LuaCov for coverage reports
luarocks install luacov

# Or install from rockspec
luarocks install nkUI-dev-1.0.rockspec
```

#### Manual Installation

1. Download Busted: https://github.com/luafun/busted
2. Download LuaCov: https://github.com/keplerproject/luacov

## Running Tests

### Run all tests

```bash
busted
```

### Run specific test file

```bash
busted spec/libekl_spec.lua
```

### Run tests with verbose output

```bash
busted --verbose
```

### Run with coverage report

```bash
busted --coverage
luacov
cat luacov.report.out
```

## Test Structure

Tests are located in the `spec/` directory with the following structure:

```
spec/
├── setup.lua              # Mock API and shared setup
├── main_spec.lua          # Main namespace tests
├── tools_spec.lua         # Tools module tests
├── libekl_spec.lua        # LibEKL function tests
└── modules/               # Module-specific tests
    ├── chat_spec.lua
    ├── questlog_spec.lua
    └── ...
```

## Writing Tests

### Basic Test Structure

```lua
require "spec.setup"  -- Load mocks and setup

describe("Module Name", function()
  describe("Feature", function()
    it("should do something", function()
      assert.is_true(true)
    end)

    it("should handle edge cases", function()
      local result = someFunction()
      assert.are.equal("expected", result)
    end)
  end)
end)
```

### Common Assertions

```lua
assert.is_true(value)
assert.is_false(value)
assert.is_nil(value)
assert.is_not_nil(value)
assert.are.equal(expected, actual)
assert.are.same(table1, table2)      -- deep equality
assert.is_not.equal(a, b)
assert.has_error(function() end)     -- expects exception
```

### Mocking

The `spec/setup.lua` provides mock implementations for:

- **Inspect API** – Game state queries (time, system, quest, unit, addon)
- **Command API** – Event attachment, console output, slash commands
- **Event constants** – Quest, Unit, System events
- **UI API** – Frame creation and manipulation
- **LibEKL** – All LibEKL utility functions

#### Adding Custom Mocks

Add mocks to `spec/setup.lua`:

```lua
function MyAPI.DoSomething()
  return "mocked result"
end
```

Then use in tests:

```lua
it("should call MyAPI", function()
  local result = MyAPI.DoSomething()
  assert.are.equal("mocked result", result)
end)
```

#### Spying on Calls

Use Busted's spy feature to track function calls:

```lua
it("should call a function", function()
  local spy_obj = spy.on(LibEKL.Events, "AddPeriodic")
  LibEKL.Events.AddPeriodic(function() end, 1, 10)
  assert.spy(spy_obj).was.called()
end)
```

## Coverage Report

After running tests with `--coverage`, LuaCov generates a detailed report:

```bash
busted --coverage
luacov
```

This creates `luacov.report.out` showing:

- Line-by-line coverage
- Uncovered lines
- Overall coverage percentage

Exclude test files and libraries with `.luacov` configuration.

## Continuous Integration

To add tests to CI/CD (GitHub Actions, GitLab CI, etc.):

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: leafo/gh-action-lua@v10
      - run: luarocks install busted
      - run: luarocks install luacov
      - run: busted --coverage
      - run: luacov
```

## Testing Strategy

### Unit Tests

Test individual functions in isolation with mocked dependencies:

```lua
describe("String utilities", function()
  it("should trim whitespace", function()
    assert.are.equal("hello", LibEKL.strings.trim("  hello  "))
  end)
end)
```

### Integration Tests

Test modules with their dependencies:

```lua
describe("Quest log with UI", function()
  it("should update UI when quest changes", function()
    -- Would test actual interaction between questLog and UI
  end)
end)
```

### Regression Tests

Add tests for any bugs found:

```lua
it("should handle nil quest details gracefully", function()
  -- Prevents future regressions
  assert.has_no.error(function()
    processQuestDetails(nil)
  end)
end)
```

## Debugging Tests

### Print debugging

```lua
it("should do something", function()
  local result = complexFunction()
  print("Result:", result)  -- visible with --verbose
  assert.is_not_nil(result)
end)
```

### Using describe.only and it.only

Run only specific tests:

```lua
describe.only("Specific feature", function()
  it.only("should work", function()
    assert.is_true(true)
  end)
end)
```

Then run: `busted` (only the "only" tests run)

### Using pending tests

Skip tests temporarily:

```lua
pending("should implement this later", function()
  assert.is_true(false)
end)
```

## Best Practices

1. **Keep tests focused** – One assertion per test when possible
2. **Use descriptive names** – `it("should return nil when quest not found")` not `it("works")`
3. **Mock external APIs** – Don't call real Rift APIs
4. **Test edge cases** – nil, empty, large values
5. **DRY with setup/teardown** – Use `before_each()` and `after_each()`
6. **Avoid test interdependence** – Each test should be independent
7. **Keep mocks simple** – Mocks should be easier than real code

## Troubleshooting

### "Module not found" errors

Ensure `require "spec.setup"` is at the top of test files.

### Mock functions not working

Check that mocks are defined before tests use them in `spec/setup.lua`.

### Tests pass locally but fail in CI

Ensure Lua version matches (5.1). Check PATH and LUA_PATH variables.

### Coverage report is incomplete

Check `.luacov` configuration includes/excludes patterns match your code.

## Resources

- [Busted Documentation](https://lunarmodules.github.io/busted/)
- [Lua Testing Best Practices](https://github.com/Olivine-Labs/busted/wiki)
- [LuaCov Documentation](https://github.com/keplerproject/luacov)
