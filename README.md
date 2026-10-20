# TaskSync — Real-Time Collaborative Task Manager

> **Final Project** untuk training **Advanced Flutter State Management with BLoC**.  
> Aplikasi produktivitas kolaboratif production-grade: workspace, Kanban board realtime, search dengan debounce, optimistic update, offline-first, dan Role-Based Access Control — semua diorkestrasi dengan BLoC.

Silabus lengkap: [`syllabus.md`](/Users/rumahcoding/Projects/Courses/Advanced%20Flutter%20State%20Management%20with%20BLoC/syllabus.md) (12 modul) · Materi: `materi/01-architecture-setup` → `materi/12-home-polish`

---

## ✨ Demo Singkat

- Login sebagai `admin@tasksync.dev` → bisa create / delete / move task.
- Login sebagai `member@tasksync.dev` → hanya read & move card.
- Gerakan task di satu device muncul di device lain **< 2 detik** saat mode Supabase aktif.
- Matikan koneksi, tandai task "Done" → UI langsung berubah (optimistic), lalu sync otomatis saat online kembali.

> Kedua akun demo menggunakan password yang sama dengan email-nya (cek `InMemoryAuthRemoteDatasource` untuk backend-free mode).

---

## 🧭 Fitur Utama

| Fitur | Deskripsi | BLoC Highlight |
|---|---|---|
| **Role-Based Auth** | Login, session, purge state saat logout | `AuthBloc` ↔ `WorkspaceBloc` / `TaskBloc` via `BlocListener` |
| **Real-Time Kanban Board** | Kolom `todo` / `doing` / `done`, drag & move | `emit.forEach` + `Stream<List<Task>>` |
| **Advanced Search** | Cari task tanpa spam request | `debounceTime(300ms)` + `restartable()` |
| **Optimistic UI** | Check "Done" terasa instant | Emit optimis → `setDone()` → rollback on error |
| **Offline-First** | Lihat & interaksi tanpa internet | `Hive` cache + `flushSyncQueue()` |
| **Error Handling Terstandar** | Network / Auth / Server dibedakan | `AppException` → `Failure` → snackbar / retry / fallback |
| **Supabase Sync** | Cross-device realtime (opt-in) | `TaskSupabaseDatasource` dengan kontrak stream yang sama |
| **RBAC 3 Lapis** | Hide UI + guard route + reject di BLoC | `RoleGate`, `authRedirect`, validasi di `TaskBloc` |
| **Polished UI** | Login aesthetic + board yang readable | Tanpa package tambahan, `buildWhen` hemat rebuild |

---

## 🏗️ Arsitektur

Feature-driven + Clean Layer (Presentation / Domain / Data).

```
lib/
├── app/
│   ├── app.dart                  # TaskSyncApp: ThemeCubit + MultiBlocProvider + BlocListener<Auth>
│   ├── router.dart               # go_router + authRedirect + RoleGate
│   └── di/injection.dart         # get_it: register DataSource → Repository → Bloc
├── core/
│   ├── theme/cubit/              # ThemeCubit (light/dark)
│   ├── error/                    # exceptions.dart (Data) & failures.dart (Domain)
│   ├── network/                  # ConnectivityService
│   └── widgets/                  # TaskCard, TaskButton, EmptyState, ErrorView
└── features/
    ├── auth/
    │   ├── data/                 # AuthRemoteDatasource (InMemory / Supabase) → AuthRepositoryImpl
    │   ├── domain/               # User, UserRole, AuthRepository (interface)
    │   └── presentation/bloc/    # AuthBloc (droppable submit & logout)
    ├── workspace/
    │   ├── data/                 # WorkspaceModel (freezed) → InMemoryWorkspaceRepository
    │   ├── domain/               # Workspace entity
    │   └── presentation/bloc/    # WorkspaceBloc (load & purge on logout)
    └── tasks/
        ├── data/                 # TaskModel (freezed), TaskLocalDatasource (Hive), TaskSupabaseDatasource
        │                         # InMemoryTaskRepository / SupabaseTaskRepository
        ├── domain/               # Task entity, TaskRepository
        └── presentation/
            ├── bloc/             # TaskBloc (lihat highlight di bawah)
            ├── pages/            # TaskBoardPage (BlocListener failure → SnackBar retry)
            └── widgets/          # KanbanBoard (per-column count, empty state, buildWhen)
```

**Aturan layer:**

- `Presentation` hanya Bloc/Cubit + Widget. Tidak memanggil Datasource langsung.
- `Domain` pure Dart (Entity + Repository interface + Failure), tanpa import Flutter.
- `Data` memetakan `Model (freezed/json)` → `Entity` di dalam Repository.
- `Bloc` tidak import `*.model.dart` — mapping terjadi di repository.

---

## 🧠 BLoC — Apa yang Diterapkan

### State Immutability & Event Modeling
- `equatable` untuk value equality.
- `freezed` untuk `TaskModel`, `UserModel`, `WorkspaceModel` — immutable, `copyWith`, union type.
- State & Event rigid (`TaskStatus: initial | loading | saving | loaded | failure`).

### Event Transformers (`bloc_concurrency` + `rxdart`)

```dart
// lib/features/tasks/presentation/bloc/task_bloc.dart
on<TaskSearchQueryChanged>(_onSearchChanged,
  transformer: debounceRestartable(const Duration(milliseconds: 300)));
on<TaskCreated>(_onCreated, transformer: droppable());   // cegah double-tap
on<TaskBoardSubcsribed>(_onBoardSubscribed, transformer: restartable());
on<TaskLoadRequested>(_onLoad, transformer: concurrent());
```

`debounceRestartable` = `debounceTime` (rxdart) + `restartable()` (bloc_concurrency).

### Multi-BLoC Communication

```dart
// lib/app/app.dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (p, c) => p.status != c.status,
  listener: (context, state) {
    if (state.status == AuthStatus.authenticated) {
      context.read<TaskBloc>().add(const TaskBoardSubcsribed());
      context.read<WorkspaceBloc>().add(const WorkspaceLoadRequested());
    }
    if (state.status == AuthStatus.unauthenticated) {
      context.read<TaskBloc>().add(const TasksPurged());
      context.read<WorkspaceBloc>().add(const WorkspacePurged());
    }
  },
)
```

Pola: **BlocListener** untuk side-effect lintas BLoC (purge data sensitif saat logout), bukan stream subscription manual.

### Real-Time Stream

```dart
// TaskBloc._onBoardSubscribed
await repository.flushSyncQueue();
await emit.forEach<List<Task>>(
  repository.watchBoard(workspaceId),
  onData: (tasks) => state.copyWith(status: TaskStatus.loaded, tasks: tasks),
  onError: (_, _) => state.copyWith(status: TaskStatus.failure, message: 'Board disconneted'),
);
```

`watchBoard` ber-return `Stream<List<Task>>`. Supabase maupun InMemory tetap memenuhi kontrak ini — `emit.forEach` tidak berubah.

### Optimistic Update

```dart
// TaskBloc._onMarkedDone
final snapshot = state.tasks;
final optimistic = snapshot.map((t) => t.id == id ? t.copyWith(isDone: isDone, isSyncing: true) : t).toList();
emit(state.copyWith(tasks: optimistic)); // UI instant
try { await repository.setDone(id: id, isDone: isDone); }
on AppException catch (e) { emit(state.copyWith(tasks: snapshot, message: e.message)); } // rollback
```

### Error Handling Terstandar

```
Datasource throws AppException (NetworkException / AuthException / ServerException / CacheException)
      ↓
Repository maps → Failure (NetworkFailure / AuthFailure / ...)
      ↓
Bloc catches AppException → state.copyWith(status: failure, message: e.message)
      ↓
UI: SnackBar + action Retry, atau ErrorView / EmptyState
```

### Role-Based Access — 3 Lapis

1. **UI**: `RoleGate` / `isRoleAllowed()` sembunyikan FAB delete untuk member.
2. **Route**: `authRedirect` + `AuthRefreshListenable` (go_router `refreshListenable` dari `authBloc.stream`) cegah akses `/board` tanpa login.
3. **BLoC**: `TaskBloc` reject event `create/delete` jika `user.role != admin` — tetap aman meski UI di-bypass.

---

## 🛠️ Tech Stack

| Kategori | Package | Versi | Kegunaan |
|---|---|---|---|
| State | `flutter_bloc` | ^9.1.1 | Bloc / Cubit / BlocListener / BlocBuilder |
| Concurrency | `bloc_concurrency` | ^0.3.0 | `droppable`, `restartable`, `concurrent` |
| Reactive | `rxdart` | ^0.28.0 | `debounceTime` |
| DI | `get_it` | ^9.3.0 | Service locator (`sl`) |
| Immutability | `equatable` | ^3.0.0 | Value equality |
| Codegen | `freezed_annotation` + `freezed` + `json_annotation` + `json_serializable` + `build_runner` | ^3.x / ^4.x / ^6.x | Model immutable & JSON |
| Local Cache | `hive` + `hive_flutter` | ^2.2.3 | Offline-first store (`Box tasksync`) |
| Navigation | `go_router` | ^18.0.2 | Auth-guarded routing |
| Backend (opt-in) | `supabase_flutter` | ^2.18.0 | Auth + Postgres + Realtime |
| Lint | `flutter_lints` | ^6.0.0 | Analyzer |

Dart SDK `^3.13.4` · Flutter `>=3.22`.

---

## 📂 Struktur File (ringkas)

```
task_sync/
├── lib/
│   ├── main.dart                 # Hive.initFlutter + Supabase.initialize (jika configured) + runApp
│   ├── app/                      # app.dart, router.dart, di/injection.dart
│   ├── core/                     # error, network, theme, widgets
│   └── features/{auth,tasks,workspace}/  # data / domain / presentation per fitur
├── test/                         # bloc_test + mocktail (AuthBloc, TaskBloc debounce)
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 🚀 Getting Started

### Prasyarat

- Flutter SDK terpasang (`flutter doctor` hijau).
- Dart `^3.13.4`.

### Install & Jalankan (backend-free, default)

```bash
git clone <repo-url> task_sync
cd task_sync

flutter pub get
dart run build_runner build --delete-conflicting-outputs  # generate *.freezed.dart & *.g.dart

flutter run
# atau
flutter run -d chrome
```

Aplikasi langsung jalan **tanpa Supabase** — menggunakan `InMemoryAuthRemoteDatasource` & `InMemoryTaskRepository` + Hive.

### Mode Supabase (realtime cross-device)

`lib/app/di/injection.dart` sudah berisi `supabaseUrl` & `supabaseAnonKey`.  
`lib/main.dart` otomatis `useSupabase: true` jika `supabaseConfigured == true`. Untuk memisahkan env, gunakan `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```

Skema minimal Supabase: `profiles`, `workspaces`, `tasks` + RLS + Realtime enabled pada tabel `tasks`. Kontrak repository tetap `Stream<List<Task>> watchBoard(workspaceId)`.

### Akun Demo

| Role | Email | Password | Hak Akses |
|---|---|---|---|
| Admin | `admin@tasksync.dev` | `admin@tasksync.dev` | create, delete, rename, move |
| Member | `member@tasksync.dev` | `member@tasksync.dev` | read & move saja |

> Pada mode in-memory, login diterima untuk kedua akun tersebut. Pada mode Supabase, buat user yang sama di Supabase Auth.

### Build

```bash
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## 🗺️ Pemetaan Silabus → Implementasi

| Modul | Topik | Implementasi di TaskSync |
|---|---|---|
| 1 | Advanced Architecture & Project Setup | `lib/app/`, `core/theme/ThemeCubit`, `core/widgets` |
| 2 | State Immutability & Event Modeling | `task_model.dart`, `user_model.dart`, `workspace_model.dart` (freezed) |
| 3 | Concurrency & Event Transformers | `TaskBloc` — `droppable`/`restartable`/`debounceRestartable`/`concurrent` |
| 4 | DI & Multi-BLoC Communication | `get_it` di `injection.dart`, `BlocListener<AuthBloc>` purge |
| 5 | Real-Time Streams | `watchBoard()` + `emit.forEach` di `TaskBloc._onBoardSubscribed` |
| 6 | Error Handling & UI Feedback | `exceptions.dart` → `failures.dart` → `SnackBar` retry / `ErrorView` |
| 7 | Optimistic & Offline | `_onMarkedDone` optimistic + `TaskLocalDatasource` + `flushSyncQueue()` |
| 8 | Testing & QA | `bloc_test` + `mocktail` — `auth_bloc_test.dart`, `task_bloc_test.dart` |
| 9 | Supabase Backend | `TaskSupabaseDatasource`, `SupabaseAuthRemoteDatasource`, opt-in switch |
| 10 | Role-Based Access | `UserRole`, `isRoleAllowed()`, `RoleGate`, guard router & BLoC |
| 11 | Login Polish | `LoginPage` — gradient, Card, logo fallback, visibility toggle |
| 12 | Home/Board Polish | `KanbanBoard` — header workspace, role badge, count per kolom, `buildWhen` |

---

## 🧪 Testing

```bash
flutter test
flutter test --coverage
flutter analyze
```

- `bloc_test` untuk `whenListen` / `expect` state sequence.
- `mocktail` untuk mock `AuthRepository` / `TaskRepository`.
- Kasus penting: login failure, debounce search, droppable create, optimistic rollback.

Generate ulang model setelah ubah freezed:

```bash
dart run build_runner build --delete-conflicting-outputs
# watch mode:
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🎨 Polish Notes

- **Login**: `LoginPage` dispatch `AuthSubmitted` saja (widget dumb), render `AuthState`. Background gradient + `Card` form + asset logo dengan fallback icon jika asset tidak ada.
- **Board**: `KanbanBoard` memakai `buildWhen` agar rebuild hanya saat `tasks`/`status` relevan berubah. Warna diambil dari `Theme` sehingga light/dark tetap konsisten. Header menampilkan workspace aktif + role badge, tiap kolom menampilkan label & count + empty state.

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---|---|
| `*.freezed.dart` / `*.g.dart` missing | `dart run build_runner build --delete-conflicting-outputs` |
| Board stuck `loading` | Cek `watchBoard` stream — pastikan `TaskBoardSubcsribed` ter-dispatch setelah login (lihat `BlocListener` di `app.dart`) |
| Supabase tidak sync | Pastikan `supabaseConfigured == true`, RLS memperbolehkan `select`/`insert`/`update` untuk user login, dan Realtime enabled di dashboard Supabase |
| Hive error di web | `Hive.initFlutter()` butuh `hive_flutter`; sudah di-setup di `main.dart` |

---

## 📄 Lisensi

Private — untuk keperluan training internal. Jangan publish ke `pub.dev` (`publish_to: none`).

---

<p align="center">Dibuat dengan Flutter & BLoC · TaskSync — Final Project Advanced Flutter State Management with BLoC</p>
