# SmartFinance (Group 3)

A robust, offline-first Cash Flow Management Application designed specifically for Small and Medium Enterprises (SMEs).

## 🏛 Architecture Overview

This project strictly adheres to **Clean Architecture** principles to ensure scalability, testability, and separation of concerns. The codebase is organized into distinct layers:

- **Presentation Layer (`features/`)**: Contains the UI widgets and state management.
- **Domain Layer (`domain/`)**: The core of the application. Contains business logic, pure Dart Entities, and Repository interfaces. This layer is entirely independent of any external packages or frameworks (no Isar, no Flutter UI).
- **Data Layer (`data/`)**: Implements the repository interfaces. Contains Data Sources (local/remote) and Mappers (converting between Domain Entities and Isar Models).
- **Core Layer (`core/`)**: Shared constants, themes, error handling, and reusable UI components.

## 🛠 Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing**: `go_router`
- **Local Database**: [Isar Database](https://isar.dev/) (Offline-first, high performance C++/Rust core)
- **Code Generation**: `build_runner` (for Isar models)

## 🚀 Features

- **Offline-First**: All data is securely stored locally using Isar Database. No internet connection is required.
- **Dashboard**: Real-time aggregation of income, expenses, and net cash flow.
- **Transaction Management**: Track cash flows with automated categorization.
- **Invoice Tracking**: Manage and scan invoices.
- **Reporting**: Generate cash flow summaries and export to PDF.

## ⚙️ Getting Started

1. **Prerequisites**: Ensure you have Flutter ^3.0.0 installed.
2. **Setup on Windows**: If you are developing on Windows, ensure you run VS Code as **Administrator** or enable **Developer Mode** in Windows settings. This is required for Flutter to create Symlinks during the C++ native compilation of the Isar Database.
3. **Run the App**:
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter run
   ```

## 📦 Seed Data

Upon the first launch, the app will automatically inject sample transaction data (Salary, Coffee, Groceries, Freelance) into the local database to help you test the UI immediately.
