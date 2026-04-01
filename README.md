# Tavio Frontend

Tavio is a Flutter mobile app that helps blind users discover nearby restaurants, view menus, and filter unsafe menu items based on allergy preferences. It includes an always-on voice assistant for hands-free navigation and settings control.

## Features

- Discover nearby restaurants and search by query/cuisine.
- View restaurant menus from the backend API.
- Hide menu items that match saved allergy preferences.
- Personalized recommendations section.
- Voice command support for navigation and settings.
- Local preference persistence (allergies + app toggles).
- Runtime permission checks and refresh flow.

## Tech Stack

- Flutter (Material 3)
- Dart SDK `^3.11.1`
- `http` for backend communication
- `speech_to_text` + `flutter_tts` for voice control
- `permission_handler` for runtime permissions
- `path_provider` + local JSON file storage for preferences

## Prerequisites

- Flutter SDK installed and on PATH
- A connected simulator/device

Check setup:

```bash
flutter doctor
```

## Getting Started

1. Clone and enter the project.
2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

4. Build release artifacts when needed:

```bash
flutter build apk
flutter build ios
```

## Backend Configuration

URL in `lib/utils/API_endpoints.dart`:

```dart
const String URL = 'http://44.222.171.66:8000';
```

If your backend URL changes, update this value before running.

### API Methods Used

- `GET /restaurants/`
- `GET /restaurants/{restaurantId}`
- `GET /restaurants/{restaurantId}/menu`
- `GET /discover/restaurants` (query params)
- `POST /recommendations/`

## Permissions

The app requests:

- Location
- Microphone
- Camera
- Photos

Voice control additionally requires microphone permission.

## Voice Assistant

Voice assistant is initialized at startup and can be paused/resumed from the app bar icon.

Example commands:

- `go to find`
- `go to settings`
- `open allergies`
- `refresh permissions`
- `turn on notifications`
- `turn off location`
- `toggle voice assistant`
- `toggle search history`
- `reset preferences`
- `open <restaurant name>`
- `list restaurants`
- `search <cuisine>`
- `close menu`
- `help`

## Local Data

User preferences are stored as JSON in app documents storage (`user_preferences.json`) and include:

- allergies list
- notifications toggle
- location services toggle
- voice assistant toggle
- search history toggle
- first-launch flag

Allowed allergy values come from `lib/utils/info/allergies.txt`.


