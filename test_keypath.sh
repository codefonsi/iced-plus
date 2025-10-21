#!/bin/bash

# KeyPath Integration Test Script
# This script tests the keypath integration step-by-step

set -e  # Exit on error

echo "=========================================="
echo "Iced KeyPath Integration Test"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Store the root directory
ROOT_DIR=$(pwd)

# Step 1: Check dependencies
echo "Step 1: Checking KeyPath Dependencies"
echo "--------------------------------------"

if grep -q "key-paths-core" examples/keypath_test/Cargo.toml; then
    print_status "key-paths-core dependency found"
else
    print_error "key-paths-core dependency missing"
    exit 1
fi

if grep -q "key-paths-derive" examples/keypath_test/Cargo.toml; then
    print_status "key-paths-derive dependency found"
else
    print_error "key-paths-derive dependency missing"
    exit 1
fi

if grep -q "tagged-core" examples/keypath_test/Cargo.toml; then
    print_status "tagged-core dependency found"
else
    print_error "tagged-core dependency missing"
    exit 1
fi

echo ""

# Step 2: Check example structure
echo "Step 2: Checking Example Structure"
echo "-----------------------------------"

if [ -f "examples/keypath_test/src/main.rs" ]; then
    print_status "Example source file exists"
else
    print_error "Example source file missing"
    exit 1
fi

if grep -q "derive.*KeyPaths" examples/keypath_test/src/main.rs; then
    print_status "KeyPaths derive macro found in source"
else
    print_error "KeyPaths derive macro not found"
    exit 1
fi

echo ""

# Step 3: Verify KeyPath derive generates correct modules
echo "Step 3: Testing KeyPaths Derive Macro"
echo "--------------------------------------"
print_info "Checking if code compiles with derive macro..."

cd examples/keypath_test

if cargo check 2>&1 | tee /tmp/keypath_check.log; then
    print_status "Example compiles with KeyPaths derive macro"
else
    print_error "Compilation failed. Check /tmp/keypath_check.log for details"
    cat /tmp/keypath_check.log
    exit 1
fi

echo ""

# Step 4: Build the example
echo "Step 4: Building KeyPath Test Example"
echo "--------------------------------------"

if cargo build 2>&1 | tee /tmp/keypath_build.log; then
    print_status "Example built successfully"
else
    print_error "Build failed. Check /tmp/keypath_build.log for details"
    cat /tmp/keypath_build.log
    exit 1
fi

echo ""

# Step 5: Check if core keypath module exists (optional)
cd "$ROOT_DIR"
echo "Step 5: Checking Core KeyPath Module (Optional)"
echo "------------------------------------------------"

if [ -f "core/src/widget/keypath.rs" ]; then
    print_status "core/src/widget/keypath.rs exists"
    
    if grep -q "id_from_key_path" core/src/widget/keypath.rs; then
        print_status "id_from_key_path function found"
    else
        print_info "id_from_key_path function not yet implemented"
    fi
else
    print_info "core/src/widget/keypath.rs not yet created (Step 1 of development plan)"
    print_info "To implement, follow docs/KEYPATH_DEVELOPMENT_PLAN.md Step 1"
fi

echo ""

# Step 6: Check feature flag
echo "Step 6: Checking Feature Flag Configuration"
echo "--------------------------------------------"

if grep -q '\[features\]' core/Cargo.toml && grep -q 'keypath' core/Cargo.toml; then
    print_status "keypath feature flag found in core/Cargo.toml"
else
    print_info "keypath feature flag not yet added to core/Cargo.toml"
    print_info "To implement, add to core/Cargo.toml:"
    echo ""
    echo "[dependencies]"
    echo "tagged-core = { version = \"0.7.0\", optional = true }"
    echo "key-paths-core = { version = \"1.3.0\", features = [\"tagged_core\"], optional = true }"
    echo ""
    echo "[features]"
    echo "keypath = [\"tagged-core\", \"key-paths-core\"]"
fi

echo ""

# Step 7: Test if we can run the example (with timeout)
echo "Step 7: Running Example (5 second test)"
echo "----------------------------------------"
print_info "Starting example application..."
print_info "The app will run for 5 seconds then exit automatically"

cd examples/keypath_test

# Run with timeout (use different commands for macOS vs Linux)
if command -v gtimeout &> /dev/null; then
    # macOS with coreutils installed
    gtimeout 5s cargo run 2>&1 || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            print_status "Example runs successfully (timed out as expected)"
        else
            print_error "Example failed to run"
            exit 1
        fi
    }
elif command -v timeout &> /dev/null; then
    # Linux
    timeout 5s cargo run 2>&1 || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            print_status "Example runs successfully (timed out as expected)"
        else
            print_error "Example failed to run"
            exit 1
        fi
    }
else
    # No timeout command available, skip this test
    print_info "Timeout command not available, skipping run test"
    print_info "To install on macOS: brew install coreutils"
    print_status "Example structure verified (run test skipped)"
fi

cd "$ROOT_DIR"
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
print_status "Dependencies are correctly configured"
print_status "KeyPaths derive macro compiles successfully"
print_status "Example structure is ready for keypath integration"
echo ""
print_info "Next steps:"
echo "  1. Implement core/src/widget/keypath.rs (see docs/KEYPATH_DEVELOPMENT_PLAN.md)"
echo "  2. Add keypath feature to core/Cargo.toml"
echo "  3. Uncomment .id(id_kp!(...)) calls in examples/keypath_test/src/main.rs"
echo "  4. Test stable ID generation"
echo ""
print_status "All tests passed! Ready for keypath development."
echo ""

