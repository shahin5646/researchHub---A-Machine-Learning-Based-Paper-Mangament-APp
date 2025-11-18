# Firebase Deployment Script
# Run this script to deploy Firestore indexes and security rules

Write-Host "=== Firebase Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✓ Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Firebase CLI not found!" -ForegroundColor Red
    Write-Host "Install with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Step 1: Initialize Firebase (if needed) ===" -ForegroundColor Cyan
Write-Host "If you haven't initialized Firebase, you'll need to:"
Write-Host "1. Run: firebase login"
Write-Host "2. Run: firebase init firestore"
Write-Host "3. Select your project"
Write-Host ""

$continue = Read-Host "Have you initialized Firebase? (y/n)"
if ($continue -ne 'y') {
    Write-Host "Please initialize Firebase first, then run this script again." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== Step 2: Deploy Firestore Indexes ===" -ForegroundColor Cyan
Write-Host "Deploying indexes from firestore_indexes_onboarding.json..." -ForegroundColor Yellow

# Copy indexes to firestore.indexes.json if it exists
if (Test-Path "firestore.indexes.json") {
    $mergeIndexes = Read-Host "Merge with existing firestore.indexes.json? (y/n)"
    if ($mergeIndexes -eq 'y') {
        Write-Host "Please manually merge firestore_indexes_onboarding.json into firestore.indexes.json" -ForegroundColor Yellow
        Write-Host "Then press Enter to continue..."
        Read-Host
    }
} else {
    Copy-Item "firestore_indexes_onboarding.json" "firestore.indexes.json"
    Write-Host "✓ Created firestore.indexes.json" -ForegroundColor Green
}

Write-Host "Deploying indexes..." -ForegroundColor Yellow
firebase deploy --only firestore:indexes

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Indexes deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Index deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Step 3: Deploy Security Rules ===" -ForegroundColor Cyan
Write-Host "Deploying rules from firestore_rules_onboarding.rules..." -ForegroundColor Yellow

# Copy rules to firestore.rules if it exists
if (Test-Path "firestore.rules") {
    $mergeRules = Read-Host "Replace existing firestore.rules? (y/n)"
    if ($mergeRules -eq 'y') {
        Copy-Item "firestore_rules_onboarding.rules" "firestore.rules"
        Write-Host "✓ Replaced firestore.rules" -ForegroundColor Green
    } else {
        Write-Host "Please manually merge firestore_rules_onboarding.rules into firestore.rules" -ForegroundColor Yellow
        Write-Host "Then press Enter to continue..."
        Read-Host
    }
} else {
    Copy-Item "firestore_rules_onboarding.rules" "firestore.rules"
    Write-Host "✓ Created firestore.rules" -ForegroundColor Green
}

Write-Host "Deploying rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Rules deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Rules deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter run"
Write-Host "2. Test new user registration"
Write-Host "3. Verify onboarding flow"
Write-Host "4. Upload a public paper"
Write-Host "5. Check that hasPublicProfile is set to true"
Write-Host ""
Write-Host "See TESTING_GUIDE.md for detailed testing instructions" -ForegroundColor Yellow
