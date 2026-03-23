# Flutter TaskManager (BLoC & Offline-First)

This is a robust, production-ready Todo application built with Flutter. It demonstrates a feature-first architecture, strict adherence to the BLoC pattern for state management, optimistic UI updates, and a comprehensive offline-first caching strategy.

## Video Demonstration
[🎥 **Click here to watch the End-to-End Video Demonstration**](https://github.com/thisisroshans/flutter_application_1/raw/refs/heads/main/flutter_application_1_e2e.webm)
## Features

- Full CRUD: View, add, update (mark complete), and delete tasks.
- Optimistic UI: Instantaneous state updates without waiting for network responses.
- Offline-First: Read and write tasks even without an internet connection.
- Background Sync: Automatically queues offline actions and syncs them when the connection is restored.
- Mock Authentication: Protected routes requiring user login.
- Search & Filter: Real-time task filtering via search.
- Pull-to-Refresh: Manually trigger a synchronization with the remote server.

## Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/thisisroshans/flutter_application_1.git
    cd flutter_application_1
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Hive Adapters:**
    > **Note:** This project uses Hive for local storage. You must generate the TypeAdapters before running the app.
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

### Demo Credentials

The application starts with a mock login screen. Use the following credentials to access the app:

-   **Username:** `admin`
-   **Password:** `password`

## How the App Functions

### The User Flow

1.  **Authentication:** The app boots to `LoginScreen`. Entering the demo credentials triggers the `AuthBloc`, transitioning the user to the `TodosScreen`.
2.  **Initial Load:** Upon loading `TodosScreen`, the `TodoBloc` fires a `LoadTodos` event. The app checks network connectivity; if online, it fetches from the JSONPlaceholder API and caches locally. If offline, it loads directly from the local Hive cache.
3.  **Adding a Task:** Tapping the FAB opens a bottom sheet. Entering a task creates a temporary, mathematically safe 32-bit ID (using bitwise masking `DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF` to comply with Hive's integer limits).
4.  **Interacting:** Checking off a task or deleting a task instantly updates the UI (Optimistic Update) while silently sending the `PATCH` or `DELETE` request to the server in the background.
5.  **Searching:** Typing in the search bar triggers a debounced search event, filtering the local state in real-time without making unnecessary API calls.

## Architecture and Design Decisions

### Feature-First Architecture

The project is structured around features rather than by layer. This approach improves scalability, modularity, and makes finding domain-specific logic much easier.

```
lib/
├── src/
│   ├── app.dart              # Root widget, handles auth routing via BlocBuilder
│   ├── core/
│   │   ├── api/              # ApiClient with Cloudflare/Bot-protection bypass headers
│   │   ├── local_storage/    # Hive local caching service
│   │   └── network/          # Network connectivity checker
│   │
│   └── features/
│       ├── auth/             # Authentication feature (UI & BLoC)
│       └── todos/            # Todos feature
│           ├── bloc/         # TodoBloc, Events, States
│           ├── data/         # Models, Hive Adapters, Repository
│           ├── view/         # Main Screens
│           └── widgets/      # Reusable UI components (TodoItem)
```

### BLoC Pattern & Optimistic Updates

The application relies strictly on `flutter_bloc` to decouple the presentation layer from business logic.

**The Optimistic Update Cycle:**
To make the application feel lightning-fast, we do not show loading spinners for minor actions (like checking a box).

1.  **Action:** User checks a task as complete.
2.  **Immediate UI Update:** The `TodoBloc` immediately copies the current state, modifies the specific task, and emits a new `TodoLoaded` state. The UI updates instantly.
3.  **Network Call:** The BLoC instructs the `TodoRepository` to send the `PATCH` request to the API.
4.  **Error Handling (Rollback):** If the API call fails (e.g., server down), the BLoC catches the error, reverts the state to the original `TodoLoaded` list, and emits a `TodoError` to trigger a `SnackBar` notifying the user of the failure.

## Offline Support & Sync Strategy

The app utilizes a robust offline-first strategy powered by Hive (a fast, lightweight NoSQL database for Flutter).

### 1. Local Caching Mechanism

The `TodoRepository` acts as the single source of truth.

-   **Reading:** When fetching tasks, it checks `NetworkInfo`. If online, it pulls from the API and immediately overwrites the Hive cache. If offline, it reads directly from Hive.
-   **Writing:** All creations, updates, and deletions are saved to Hive first, ensuring the local database is always up to date regardless of network status.

### 2. Background Syncing (Action Queue)

When the user modifies a task while offline, the app cannot reach the JSONPlaceholder API.

-   The `TodoRepository` catches the `SocketException` or `UnauthorisedException`.
-   Instead of discarding the action, the `LocalCacheService` saves the action to a "Queued Actions List" (e.g., `{'type': 'create', 'data': {...}}`).
-   The repository listens to network status changes. When the connection is restored, it triggers the `syncPendingChanges()` method.
-   The app iterates through the queue, re-attempts the API calls in the background, and clears the queue upon success, ensuring no data is ever lost.

## Challenges & Solutions

-   **Cloudflare API Blocking:**
    -   **Challenge:** Initial `http` requests to the JSONPlaceholder API were intercepted and blocked by Cloudflare returning HTML (403 Forbidden) pages, assuming the Flutter app was a bot.
    -   **Solution:** Injected standard browser `User-Agent` and `Accept: application/json` headers into the `ApiClient` to securely bypass the bot protection.

-   **Hive 32-Bit Integer Limits vs. Milliseconds:**
    -   **Challenge:** Generating temporary IDs for offline task creation using `DateTime.now().millisecondsSinceEpoch` resulted in a 64-bit integer. Hive strictly requires 32-bit integers for keys, causing a fatal crash (`HiveError: Integer keys need to be in the range 0 - 0xFFFFFFFF`).
    -   **Solution:** Implemented a bitwise AND operator mask (`& 0x7FFFFFFF`) when generating the ID. This instantly chops the 64-bit timestamp down into a safe, positive 32-bit integer, guaranteeing Hive compatibility without the risk of random number collisions.

-   **Search State Preservation:**
    -   **Challenge:** When a user had an active search query (e.g., "Buy groceries") and toggled a task as complete, the BLoC's optimistic update was accidentally resetting the active `filteredTodos` list back to the `allTodos` list, breaking the UI search state.
    -   **Solution:** Updated the `TodoBloc` to store `_currentSearchQuery` in memory. Created a helper function `_applySearchFilter()` that is run on every emitted state, ensuring that CRUD actions never interrupt an active search session.
## LICENSE
SOFTWARE OWNED BY ROSHAN SINGH
