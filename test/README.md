# Test Directory Security Guidelines

## ⚠️ SECURITY WARNING

**NEVER include real API keys, passwords, or other sensitive data in test files!**

## Best Practices for Test Files

### 1. Use Dummy/Test Values Only
```bash
# ✅ GOOD - Use clearly fake test values
TEST_API_KEY="test_api_key_for_validation_purposes_only"
TEST_PASSWORD="dummy_password_123_NOT_REAL"
TEST_TOKEN="fake_token_abcdef_FOR_TESTING"

# ❌ BAD - Never use real credentials
REAL_API_KEY="AIzaSy...[REAL_KEY_WOULD_GO_HERE]"
```

### 2. Use Environment Variables for Integration Tests
```bash
# ✅ GOOD - Use environment variables for tests that need real data
if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    run_integration_test
else
    echo "Skipping integration test - no API key provided"
fi
```

### 3. File Naming Convention
- `*-test.sh` - Unit tests with dummy data only
- `*-integration-test.sh` - Tests that may use real env vars (document clearly)
- `*-with-secrets.*` - Automatically ignored by .gitignore

### 4. Documentation Requirements
Every test file should include a security header:
```bash
#!/usr/bin/env bash
# SECURITY: This file uses only test/dummy values - never real API keys!
```

## Running Tests

### Unit Tests (Safe to run anywhere)
```bash
./test/validation-test.sh
./test/test-environment-loading.sh
```

### Integration Tests (Require real environment)
```bash
# Set up test environment first
export GEMINI_API_KEY="your_real_key_here"
./test/integration-test.sh
```

## Security Checklist

Before committing any test file:
- [ ] Does it contain only dummy/test values?
- [ ] Are real API keys/secrets removed?
- [ ] Is the security header present?
- [ ] Would I be comfortable if this were public on GitHub?

## .gitignore Protection

The following patterns automatically prevent committing sensitive test files:
- `**/test/*-with-secrets.*`
- `**/test/*-real-*`
- `test/**/*-private.*`
