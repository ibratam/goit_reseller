# goit_reseller

A Flutter starter app with:

- login screen
- authenticated customer service search
- add-credit action from search results
- my transactions page with filters and pagination
- real API integration for login, current user, logout, search, add-credit, and transactions

## Current status

This repository was empty, so the app scaffold was created manually. The Flutter SDK is not available in this environment, so platform folders were not generated and commands were not executed here.

## Next steps

1. Install Flutter locally if it is not already installed.
2. Commit the current scaffold before generating platform folders.
3. Run `flutter create .` from the repository root to generate the missing Flutter project files.
4. If Flutter asks to overwrite existing Dart app files, keep the current `lib/` and `test/` files from this scaffold.
5. Run `flutter pub get`.
6. Update `.env` with your API settings.
7. Start the app with `flutter run`.

## Implemented endpoints

- `POST /api/users/login`
- `GET /api/users`
- `POST /api/users/logout`
- `GET /api/users/transactions`
- `GET /api/customers/services/search`
- `POST /api/customers/add-credit`

## Configuration

The app now reads configuration from [.env](/Users/macbook/Documents/projects/flutter/goit_reseller/.env).

Example:

```env
API_BASE_URL=http://con.goit.ps:8090
API_DEVICE_NAME=mobile-app
```

You can still override either value with `--dart-define` if needed:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-domain.com \
  --dart-define=API_DEVICE_NAME=mobile-app
```
