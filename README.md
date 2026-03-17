
# Flutter Todo Application

This is a robust Todo application built with Flutter, demonstrating a feature-first architecture, BLoC for state management, optimistic UI updates, and offline support.

## Features

- View, add, update, and delete todos.
- Optimistic UI updates for a smooth user experience.
- Offline support with local caching and background synchronization.
- Mock user authentication.
- Search functionality to filter todos.
- Pull-to-refresh to sync with the remote server.

## Project Structure

The project follows a feature-first architecture, where code is organized by feature (e.g., `auth`, `todos`) rather than by layer (e.g., `bloc`, `ui`). This approach improves scalability and modularity.

```
lib
├── src
│   ├── app.dart              # Root widget, handles auth routing
│   ├── main.dart             # App entry point
│   ├── service_locator.dart  # Service locator setup (if used)
│   │
│   ├── core
│   │   ├── api/              # API client and exceptions
│   │   ├── local_storage/    # Local caching service
│   │   └── network/          # Network connectivity checker
│   │
│   └── features
│       ├── auth/             # Authentication feature
│       │   ├── bloc/
│       │   └── view/
│       │
│       └── todos/            # Todos feature
│           ├── bloc/
│           ├── data/
│           │   ├── models/
│           │   └── todos_repository.dart
│           ├── view/
│           └── widgets/
│
└── ...
```

## Setup and Installation

1.  **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd flutter_todo_app
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Run the application:**
    ```sh
    flutter run
    ```

The application will start with a mock login screen. Use the following credentials:
-   **Username:** `admin`
-   **Password:** `password`

## Architecture and Design Decisions

### Feature-First Architecture
This project is structured around features (`auth`, `todos`) to promote modularity and separation of concerns. Each feature contains its own BLoCs, UI, and data logic, making the codebase easier to navigate, maintain, and scale.

### Authentication Routing
The root of the application (`app.dart`) uses a `BlocBuilder` on the `AuthBloc` to manage routing. If the user is `unauthenticated`, it shows the `LoginScreen`. Once `authenticated`, it transitions to the `TodosScreen`. This ensures that protected routes are only accessible after a successful login.

### BLoC Pattern and Optimistic Updates
The BLoC (Business Logic Component) pattern is used for state management, decoupling the UI from the business logic.

-   **Events:** UI components dispatch events (e.g., `AddTask`, `ToggleTaskCompletion`) to the `TodosBloc`.
-   **States:** The `TodosBloc` processes these events, interacts with the `TodoRepository`, and emits new states (`TaskLoading`, `TaskLoaded`, `TaskError`).
-   **UI:** The `BlocBuilder` widgets in the UI layer listen for state changes and rebuild accordingly.

**Optimistic Updates:** For a seamless user experience, UI changes are applied immediately without waiting for the server's confirmation.
1.  When an event like `ToggleTaskCompletion` is dispatched, the `TodosBloc` immediately emits a new `TaskLoaded` state with the updated (toggled) todo list.
2.  It then attempts to sync this change with the remote API via the `TodoRepository`.
3.  If the API call fails, the BLoC catches the error and reverts the UI to its previous state by re-emitting the original todo list and showing an error message (e.g., using a `SnackBar`).

This approach makes the application feel fast and responsive, even on slow networks.

## Offline Support Strategy

The application is designed to work offline using a local caching and background synchronization strategy.

### Caching Mechanism
-   **LocalCacheService:** This service (implemented with `shared_preferences` in this project) is responsible for all local database operations (CRUD). It stores the list of todos in a serialized format (JSON string).
-   **TodoRepository:** This repository acts as a single source of truth. When fetching data, it first checks for a network connection using the `connectivity_plus` package.
    -   **Online:** It fetches fresh data from the remote API, updates the local cache with the new data, and then returns the list.
    -   **Offline:** It retrieves and returns the last known data directly from the local cache.

### Background Syncing Strategy
When the user is offline, any changes (adds, updates, deletes) are queued locally.
1.  The `TodoRepository` catches API errors that occur due to a lack of network connectivity.
2.  Instead of propagating the error, it stores the failed operation (e.g., the new todo to be created) in a separate "pending changes" queue in the `LocalCacheService`.
3.  A background process or a listener on the network status (using `connectivity_plus`) detects when the device comes back online.
4.  Once online, it triggers a `SyncTasks` event. The `TodosBloc` then processes this queue, sending all the pending changes to the remote API to synchronize the state.

## Challenges of State Synchronization

Synchronizing local and remote states presents several challenges:

1.  **Data Conflicts:** What happens if a todo is modified on the server while the user is offline and making local changes to the same todo?
2.  **Order of Operations:** Ensuring that queued operations are executed in the correct order is crucial to avoid data corruption.
3.  **Error Handling:** If a synced operation fails (e.g., due to a server-side validation error), how do we handle it without losing the user's change?

This architecture begins to solve these issues:
-   By having the `TodoRepository` as a single source of truth, we centralize the logic for fetching and updating data, which is the first step in managing conflicts.
-   The optimistic update mechanism provides immediate feedback, but the repository's logic ensures that this is reconciled with the server state. In a more advanced implementation, the repository could implement a conflict resolution strategy (e.g., "last write wins" or prompting the user).
-   The background sync queue ensures that no data is lost during connectivity outages. For more complex scenarios, each queued item could be given a timestamp or a version number to help resolve conflicts during synchronization.
