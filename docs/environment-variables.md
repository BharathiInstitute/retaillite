# Environment Variables Reference — RetailLite

All environment variables, secrets, and configuration keys in one place.

## Build-Time Variables (--dart-define)

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `RAZORPAY_KEY_ID` | Razorpay API key (test or live) | `rzp_test_xxx` / `rzp_live_xxx` | Yes |

### Usage
```bash
# Development (test mode)
flutter run --dart-define=RAZORPAY_KEY_ID=rzp_test_SBggB4lYrbT8Sr

# Production release
flutter build apk --release --obfuscate --split-debug-info=build/debug-info --dart-define=RAZORPAY_KEY_ID=rzp_live_YOURKEY
flutter build web --release --dart-define=RAZORPAY_KEY_ID=rzp_live_YOURKEY
```

## Firebase Cloud Functions Config

Set via: `firebase functions:config:set <key>=<value>`

| Key | Description | Required |
|-----|-------------|----------|
| `razorpay.key_id` | Razorpay Key ID | Yes |
| `razorpay.key_secret` | Razorpay Key Secret | Yes |
| `razorpay.webhook_secret` | Razorpay Webhook Secret (for signature verification) | Yes |

## Firebase Remote Config Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `maintenance_mode` | bool | `false` | Show maintenance screen to all users |
| `min_app_version` | string | `1.0.0` | Minimum supported app version (force update below this) |
| `force_update` | bool | `false` | Force update flag |
| `force_update_url` | string | `""` | URL to redirect users for update |
| `kill_switch_payments` | bool | `false` | Disable all payment features instantly |
| `merchant_upi_id` | string | `""` | Merchant UPI ID for manual payment sharing |

## Android Signing (key.properties)

See `android/key.properties.example` for template. **Never commit `key.properties` to Git.**

| Key | Description |
|-----|-------------|
| `storePassword` | Keystore password |
| `keyPassword` | Key password |
| `keyAlias` | Key alias (e.g., `retaillite`) |
| `storeFile` | Path to `.jks` keystore file |

## GitHub Actions Secrets

Set in: GitHub → Repository Settings → Secrets and Variables → Actions

| Secret | Description |
|--------|-------------|
| `RAZORPAY_KEY_ID` | Razorpay API key for CI builds |

## Firebase Projects

| Environment | Project ID | Purpose |
|-------------|-----------|---------|
| Production | `login-radha` | Live users |
| Staging | `retaillite-staging` | Testing before production (create this) |
