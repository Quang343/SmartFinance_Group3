# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SmartFinance (`smart_finance`) — a Flutter cash-flow management app for SMEs. Cloud-synced via Firebase, with role-based access for three finance roles. **UI language is Vietnamese** (primary locale `vi_VN`); user-facing strings, labels, and error messages are written in Vietnamese.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run the app (device/emulator auto-selected)
flutter run -d chrome           # run on web
flutter analyze                 # static analysis / lint (uses flutter_lints)
flutter test                    # run all tests
flutter test test/features/dashboard/presentation/dashboard_screen_test.dart   # run a single test file
flutter test --name "substring of test name"                                   # run tests matching a name
flutter build apk               # release build (also: appbundle, ios, web, windows)
```

## Required setup before running

- **`.env` must exist at the repo root** — `main.dart` calls `dotenv.load(fileName: ".env")` at startup and the app crashes without it. It is registered as a Flutter asset in `pubspec.yaml`. Copy `.env.example` to `.env` and set `IMGBB_API_KEY` (image uploads throw a Vietnamese error if the key is missing/placeholder). `.env` is git-ignored.
- **Firebase must be configured** with Firestore + Authentication (Email/Password and Google) enabled. `firebase_options.dart` and `android/app/google-services.json` are committed.

## Architecture

Clean Architecture in four layers under `lib/`:

- **`features/<feature>/`** — presentation layer: screens (`presentation/`) and feature-scoped providers (`providers/`).
- **`domain/`** — pure Dart: `entities/`, repository **interfaces** (`repositories/`), and stateless business logic in `services/` (e.g. `CashFlowCalculator`, `ReportCalculator`, `VatCalculator` — static methods over entity lists).
- **`data/`** — `models/` (extend domain entities, add `fromJson`/`toJson`) and repository **implementations** (`repositories/`, `*Impl` suffix) backed by Firestore.
- **`core/`** — shared constants, providers (DI), theme-independent utils, reusable widgets.
- **`app/`** — `app.dart` (root `MaterialApp.router`), `router.dart` (go_router), `theme/`.

### Dependency injection & state (Riverpod)

- Repositories are wired in **`lib/core/providers/app_providers.dart`**, constructed directly with `FirebaseFirestore.instance` / `FirebaseAuth.instance`. Consume repos via these providers, not by instantiating impls.
- **Two provider locations exist and differ.** `lib/core/providers/*` holds the real DI and data providers (e.g. `transaction_providers.dart` exposes `FutureProvider.autoDispose` lists like `expenseTransactionsProvider`). Several `lib/features/*/providers/*` files are **stubs** (`// To be implemented`) — check before assuming a feature provider works; put new real logic in the appropriate place rather than trusting the stub name.
- `auth_repository.dart` and `storage_repository.dart` (in `data/repositories/`) are exceptions to the interface pattern: they have **no** domain interface and declare their own provider inline.

### Firestore data model

All business data is **scoped under the current user**: `users/{uid}/transactions`, and similarly for categories/invoices/attachments. Repository impls derive the uid from `FirebaseAuth.instance.currentUser` and return empty/no-op when there is no signed-in user. Enums are serialized by `.name` (e.g. `type`, `status`). **Monetary amounts are stored as `int`** (whole VND, no decimals).

Soft delete: entities carry a `status` (e.g. `draft` / `confirmed` / `deleted`). Deletes set status to `deleted`; `cleanupDeletedTransactions()` permanently purges records deleted >30 days ago.

### Auth & current user

`currentUserProvider` (a `StateProvider<UserModel?>` in `core/providers/auth_provider.dart`) is the app's notion of "who is logged in" and is set/cleared **manually** (login screens set it; logout sets it to `null` then navigates to `/welcome`). It is distinct from the FirebaseAuth session. Role-based UI reads from it.

### Role-based access control

`UserRole` (`core/providers/role_provider.dart`) has three roles — `financeManager`, `expenseAccountant`, `revenueAccountant` — each with a Vietnamese label (`nameVi`) and capability getters (`canEditTransactions`, `canManageIncomingInvoices`, etc.). `roleProvider` maps `currentUser.role` (a string) to the enum. **Navigation items are role-driven**: `ResponsiveLayout` builds a different nav set per role.

### Routing & responsive shell

`go_router` in `app/router.dart`, `initialLocation: '/splash'`. Auth flow screens (splash, onboarding, welcome, login, register, forgot-password, notifications) are top-level routes; all main app screens live inside a `ShellRoute` whose builder wraps children in **`ResponsiveLayout`** (`core/widgets/responsive_layout.dart`). That widget switches on width at 800px: `BottomNavigationBar` + `Drawer` for mobile, `NavigationRail` for desktop. Route names are centralized in `core/constants/route_names.dart`.

### Startup seeding

`FirebaseSeedService.seedDefaultUsers()` runs in `main()` before the app renders. On an empty backend it creates three test accounts (one per role, password `123456`) in Firebase Auth + Firestore; it no-ops on `email-already-in-use`. Useful for testing the RBAC flow immediately.

## Testing conventions

- Uses `flutter_test` + `mocktail`. Test tree mirrors `lib/` under `test/`.
- **`test/helpers/test_utils.dart`** provides `createTestApp(widget, overrides: [...])` (wraps in `ProviderScope` + `MaterialApp`) and `FakeTransactionRepository`. Widget tests inject fakes via Riverpod provider `overrides` rather than real Firebase.

## Notable dependencies

Firebase (`firebase_core`, `cloud_firestore`, `firebase_auth`, `google_sign_in`); **image storage is ImgBB via `http`** (not Firebase Storage, despite the `firebase_storage` dependency being present); `fl_chart` (dashboard/report charts); `pdf` + `printing` + `screenshot` (invoice/report PDF export); `image_picker` (invoice scan/avatar); `intl` (Vietnamese formatting); default avatars from DiceBear.
