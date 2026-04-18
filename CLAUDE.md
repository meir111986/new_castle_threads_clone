# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run code generation (after modifying Freezed models or Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Analyze code
flutter analyze
```

## Architecture

The app follows **Clean Architecture** with three layers and BLoC/Cubit state management:

```
lib/
├── domain/          # Entities + abstract repository interfaces
├── data/            # Repository implementations, remote (Supabase) + local (Hive) data sources, Freezed models
├── presentation/    # Screens, widgets, Cubit + State classes
└── locator.dart     # GetIt dependency injection setup
```

### Dependency Injection

All dependencies are registered in `lib/locator.dart` via `setupDependencies()`, called in `main()` before `runApp()`. Uses `get_it` as a service locator with lazy singletons. Order of registration: external services (SupabaseClient, ImagePicker) → data sources → repositories.

### State Management

Each feature has a `Cubit` + `State` pair (using Freezed). States use an enum for status (`initial`, `loading`, `success/loaded`, `error/failure`). Key cubits:
- `AuthCubit` — auth state, listens to `AuthRepository.authStateChanges` stream
- `FeedCubit` — feed posts, optimistic like updates
- `CreatePostCubit` — post creation with image picking via `ImagePicker`
- `CommentsCubit` — per-post comments
- `ProfileCubit` — user profile + their posts (currently uses mock user data)

### Data Flow

Repositories try remote (Supabase) first, then cache results locally in Hive. On remote failure, they fall back to the Hive cache. `PostRepositoryImpl` and `CommentRepositoryImpl` implement this pattern.

Domain entities (`Post`, `Comment`, `AuthUser`, `User`) are separate from data models (`PostModel`, `CommentModel`). Models are Freezed + Hive-annotated; entities are plain Dart classes. Repositories convert between them.

### Code Generation

Freezed models and Hive adapters require `build_runner`. Any file with `@freezed`, `@JsonSerializable`, or `@HiveType` annotations needs codegen. Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.

### Environment

Supabase credentials (`API_URL`, `API_KEY`) are loaded from a `.env` file via `flutter_dotenv`. The `.env` file is listed as an asset in `pubspec.yaml` and must exist at project root.

### Navigation

No routing library — uses `Navigator.push` directly throughout the presentation layer.
