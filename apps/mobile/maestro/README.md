# Karakeep Mobile E2E Tests

This directory contains end-to-end tests for the Karakeep mobile app using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

1. **Install Maestro**:

   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. **Set up test environment**:

   - iOS: Xcode and iOS Simulator
   - Android: Android Studio and Android Emulator

3. **Build the app**:

   ```bash
   # iOS
   pnpm ios

   # Android
   pnpm android
   ```

## Test Structure

```
maestro/
├── flows/
│   ├── 01-auth-setup.yaml      # Sign in flow (reusable)
│   ├── 02-share-url.yaml       # Test URL sharing (working)
│   └── 03-share-pdf.yaml       # Test PDF sharing (to be implemented)
├── helpers/
│   ├── test-data-setup.sh      # Sets up test PDFs on devices
│   └── test-document.pdf       # Sample PDF for testing
└── README.md
```

## Running Tests

1. **Set up test data**:

   ```bash
   cd apps/mobile
   ./maestro/helpers/test-data-setup.sh
   ```

2. **Run all tests**:

   ```bash
   maestro test maestro/flows/
   ```

3. **Run specific test**:

   ```bash
   # Test URL sharing only
   maestro test maestro/flows/02-share-url.yaml

   # Test PDF sharing only
   maestro test maestro/flows/03-share-pdf.yaml
   ```

## Test Cases

### 1. URL Sharing (Currently Working)

- Opens Safari/Chrome
- Navigates to a test URL
- Triggers share sheet
- Selects Karakeep
- Verifies bookmark is created

### 2. PDF Sharing (To Be Implemented)

- Opens Files app
- Selects test PDF
- Triggers share sheet
- Selects Karakeep
- Should create bookmark with PDF asset

## Current Status

✅ **Working**:

- URL sharing from browsers
- Authentication flow
- Basic bookmark creation

❌ **Not Working** (PDF sharing):

- Share extension doesn't properly handle PDF files
- Missing PDF type detection in `sharing.tsx`
- Asset upload may need adjustments for PDFs

## Implementation Notes for PDF Feature

The PDF sharing test is designed to fail initially. To make it pass, you'll need to:

1. **iOS**: Update `ShareViewController.swift` to properly handle `kUTTypePDF`
2. **Android**: Ensure intent filters accept `application/pdf` MIME type
3. **React Native**: Update `sharing.tsx` to detect and handle PDF files
4. **Backend**: Ensure PDF upload and processing works correctly

## Debugging

- Use `maestro studio` for interactive test development
- Check device logs for share extension errors
- Verify test PDF exists in the expected location

## Environment Variables

Configure in `.maestro/config.yaml`:

- `APP_ID`: Bundle identifier
- `SERVER_URL`: Karakeep server URL
- `TEST_EMAIL`: Test account email
- `TEST_PASSWORD`: Test account password
