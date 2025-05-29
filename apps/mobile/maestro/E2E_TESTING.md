# Karakeep Mobile E2E Testing Guide

This guide provides comprehensive instructions for running end-to-end tests for the Karakeep mobile app.

## Quick Start

```bash
# 1. Start the complete test environment
pnpm test:e2e:env:start

# 2. In a new terminal, build and run the app
pnpm ios  # or pnpm android

# 3. Run all E2E tests
pnpm test:e2e

# 4. Clean up when done
pnpm test:e2e:env:stop
```

## What the Test Environment Provides

The `test:e2e:env:start` script sets up a complete, isolated testing environment:

1. **Karakeep Server**: Runs on http://localhost:3001 (separate from dev port 3000)
2. **SQLite Database**: Created in `data-test/` directory with test migrations
3. **Meilisearch**: Full-text search engine on port 7701 (if Docker is available)
4. **Background Workers**: Processes crawling, AI tasks, etc.
5. **Test User**: Automatically created with credentials:
   - Email: `test@example.com`
   - Password: `testpassword123`

## Prerequisites

### Required

- Node.js 22 or later
- pnpm (`npm install -g pnpm`)
- Xcode (for iOS testing) or Android Studio (for Android testing)
- Maestro (`curl -Ls "https://get.maestro.mobile.dev" | bash`)

### Optional

- Docker (for Meilisearch - tests work without it but search features won't)

## Test Structure

```
maestro/
├── E2E_TESTING.md              # This file
├── README.md                   # Basic test documentation
├── .maestro/
│   └── config.yaml            # Test configuration (auto-updated)
├── flows/
│   ├── 01-auth-setup.yaml     # Reusable sign-in flow
│   ├── 01-auth-setup-dev.yaml # Sign-in for dev builds
│   ├── 02-share-url.yaml      # URL sharing test
│   ├── 03-share-pdf.yaml      # PDF sharing test
│   └── *.yaml                 # Additional test flows
└── helpers/
    ├── start-test-environment.sh  # Complete env setup
    ├── stop-test-environment.sh   # Clean shutdown
    ├── run-ios-test.sh           # iOS test runner
    ├── test-data-setup.sh        # Test file setup
    ├── generate-test-pdf.js      # PDF generator
    └── test-document.pdf         # Sample PDF
```

## Available Commands

### Environment Management

- `pnpm test:e2e:env:start` - Start complete test environment
- `pnpm test:e2e:env:stop` - Stop test environment

### Test Execution

- `pnpm test:e2e` - Run all tests
- `pnpm test:e2e:ios` - Run tests on iOS (auto-detects simulator)
- `pnpm test:e2e:url` - Test URL sharing only
- `pnpm test:e2e:pdf` - Test PDF sharing only
- `pnpm test:e2e:studio` - Interactive test builder

### Test Data

- `pnpm test:e2e:setup` - Set up test PDFs on device

## Writing New Tests

### Basic Test Structure

```yaml
appId: ${APP_ID}
---
# Test description

# Ensure user is signed in
- runFlow: 01-auth-setup.yaml

# Your test steps here
- tapOn: "Button Text"
- inputText: "Some text"
- assertVisible: "Expected Result"
```

### Best Practices

1. **Always use testID for reliability**:

   ```tsx
   <Button testID="save-bookmark-button">Save</Button>
   ```

2. **Handle platform differences**:

   ```yaml
   - tapOn:
       text: "Share"
       when:
         platform: iOS
   ```

3. **Wait for animations**:

   ```yaml
   - tapOn: "Submit"
   - waitForAnimationToEnd
   - assertVisible: "Success"
   ```

4. **Use optional for flaky elements**:
   ```yaml
   - tapOn:
       text: "Continue"
       optional: true
   ```

## Troubleshooting

### Common Issues

1. **"Expo Developer Tools" screen appears**

   - Use `01-auth-setup-dev.yaml` instead of `01-auth-setup.yaml`
   - This handles the Expo development server selection

2. **Test user already exists**

   - This is normal - the setup script handles existing users
   - The test will proceed normally

3. **Port 3001 already in use**

   - Run `pnpm test:e2e:env:stop` to clean up
   - Or manually: `lsof -ti:3001 | xargs kill -9`

4. **Meilisearch not starting**
   - Docker is optional - tests work without search
   - Install Docker if you need to test search features

### Debugging

1. **Check server logs**:

   ```bash
   tail -f test-server.log
   ```

2. **Check worker logs**:

   ```bash
   tail -f test-workers.log
   ```

3. **Use Maestro Studio**:

   ```bash
   pnpm test:e2e:studio
   ```

4. **View test recordings**:
   - Failed tests save screenshots to `~/.maestro/tests/`

## Clean Up

### After Testing

```bash
# Stop all services
pnpm test:e2e:env:stop
```

### Complete Clean (including test data)

```bash
# Stop services
pnpm test:e2e:env:stop

# Remove test database and files
rm -rf data-test/

# Remove test environment file
rm -f .env.test
```

## CI/CD Integration

For CI environments, you can run tests headlessly:

```bash
# Start environment
./maestro/helpers/start-test-environment.sh

# Build app (example for iOS)
eas build --local --platform ios --profile preview

# Install on simulator
xcrun simctl install booted path/to/app.ipa

# Run tests
maestro test maestro/flows/

# Clean up
./maestro/helpers/stop-test-environment.sh
```

## Tips for Reliability

1. **Isolate test data**: The test environment uses separate database and ports
2. **Clean state**: Each test run starts with `launchApp: clearState: true`
3. **Predictable data**: Test user and credentials are always the same
4. **No external dependencies**: Everything runs locally (except optional Docker)

## Contributing

When adding new E2E tests:

1. Create test file in `maestro/flows/`
2. Follow naming convention: `XX-feature-name.yaml`
3. Include auth setup: `- runFlow: 01-auth-setup.yaml`
4. Add npm script if it's a common test
5. Update this documentation

## Need Help?

- Maestro docs: https://maestro.mobile.dev
- Check existing tests for examples
- Use `maestro studio` for interactive debugging
