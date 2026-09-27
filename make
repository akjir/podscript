#!/bin/sh
set -e

# Default action is 'all' if no arguments are provided
ACTION=${1:-all}

case "$ACTION" in
    dev)
        shift
        echo "=> Running dev tests..."
        lua test.lua --dev "$@"
        ;;
    build)
        shift
        echo "=> Building..."
        lua build.lua "$@"
        ;;
    test)
        shift
        echo "=> Running release tests..."
        lua test.lua "$@"
        ;;
    all)
        if [ $# -gt 0 ]; then shift; fi
        echo "=> Running dev tests..."
        lua test.lua --dev "$@"
        echo "=> Building..."
        lua build.lua
        echo "=> Running release tests..."
        lua test.lua "$@"
        echo "=> All tasks completed successfully!"
        ;;
    *)
        # Default behavior: pass arguments directly to the tests
        echo "=> Running dev tests..."
        lua test.lua --dev "$@"
        echo "=> Building..."
        lua build.lua
        echo "=> Running release tests..."
        lua test.lua "$@"
        echo "=> All tasks completed successfully!"
        ;;
esac
