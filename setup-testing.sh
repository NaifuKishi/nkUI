#!/bin/bash
# Setup script for nkUI testing with Busted

set -e

echo "=== nkUI Testing Setup ==="
echo ""

# Check for Lua
if ! command -v lua &> /dev/null; then
    echo "❌ Lua is not installed"
    echo "Install Lua 5.1 or 5.4:"
    echo "  Ubuntu/Debian: sudo apt-get install lua5.4 lua5.4-dev"
    echo "  macOS: brew install lua"
    exit 1
fi

LUA_VERSION=$(lua -v 2>&1 | cut -d' ' -f2)
echo "✓ Lua $LUA_VERSION found"

# Check for LuaRocks
if ! command -v luarocks &> /dev/null; then
    echo "❌ LuaRocks is not installed"
    echo "Install LuaRocks:"
    echo "  Ubuntu/Debian: sudo apt-get install luarocks"
    echo "  macOS: brew install luarocks"
    exit 1
fi

LUAROCKS_VERSION=$(luarocks --version | cut -d' ' -f2)
echo "✓ LuaRocks $LUAROCKS_VERSION found"

# Install test dependencies
echo ""
echo "Installing test dependencies..."
luarocks install busted 2>/dev/null && echo "✓ Busted installed" || echo "⚠ Busted already installed or failed"
luarocks install luacov 2>/dev/null && echo "✓ LuaCov installed" || echo "⚠ LuaCov already installed or failed"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Run tests with:"
echo "  busted                    # Run all tests"
echo "  busted --verbose          # Run with detailed output"
echo "  busted --coverage         # Run with coverage report"
echo ""
echo "For more information, see TESTING.md"
