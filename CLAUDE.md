# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LightWeight is an iOS workout tracker (iPhone + iPad) built with SwiftUI and SwiftData. Users build **workout templates** from a **shared exercise library**, plan target weight/reps per set, then **start a session** that logs what they actually lifted and saves it to **history**.

Single Xcode project, no Swift Package Manager, CocoaPods, or Carthage dependencies.

The implementation plan for the current iteration lives in `.claude/plans/`.

## Commands

Build for simulator:

```bash
xcodebuild -project LightWeight.xcodeproj -scheme LightWeight \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Launch in the simulator:

```bash
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator
APP_DIR=$(xcodebuild -project LightWeight.xcodeproj -scheme LightWeight \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -showBuildSettings \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{print $2; exit}')
xcrun simctl install booted "$APP_DIR/LightWeight.app"
xcrun simctl launch booted sebis.LightWeight
```

Resolve the app path via `-showBuildSettings`, **not** a `DerivedData/LightWeight-*` glob. Multiple hash-suffixed DerivedData directories for this project can coexist, and a glob sorts alphabetically rather than by build time — it will silently install a stale binary.

First launch logs a burst of `CoreData: error: Failed to stat path … default.store` / `Sandbox access to file-write-create denied`. That is normal: CoreData stats the store before creating it. Only treat it as a real failure if the store file never appears in the app container's `Library/Application Support/`.

Check available destinations with `xcrun simctl list devices available`. The scheme and target are both named `LightWeight`; the bundle identifier is `sebis.LightWeight`.

### Tests

There is no test target. `xcodebuild test` fails until one is added, which requires creating the target in Xcode (File > New > Target > Unit Testing Bundle) — it cannot be done by adding files alone. Once a test target exists, run a single test with:

```bash
xcodebuild test -project LightWeight.xcodeproj -scheme LightWeight \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:<TestTarget>/<TestClass>/<testMethod>
```

## Project structure conventions

The project uses `objectVersion = 77` with a `PBXFileSystemSynchronizedRootGroup` for the `LightWeight/` folder. **New `.swift` files placed anywhere under `LightWeight/` are compiled automatically — do not edit `project.pbxproj` to register them.** Subdirectories become groups implicitly, so organize freely on disk.

## Concurrency model

Build settings enable Swift's approachable concurrency:

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — every type and function is `@MainActor`-isolated **by default**, without annotation. Do not add redundant `@MainActor`; instead mark background-safe code `nonisolated` explicitly.
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_VERSION = 5.0` — language mode 5, so data-race safety errors surface as warnings rather than hard errors.

## Architecture

The data model splits into two halves, and **the split is the most important invariant in the codebase**:

- **Template side** (`Models/Exercise.swift`, `Models/Workout.swift`) — `Exercise` (shared library) ← `WorkoutExercise` (a slot in a workout) → `PlannedSet` (target weight/reps). This is what the user edits.
- **Session side** (`Models/WorkoutSession.swift`) — `WorkoutSession` → `SessionExercise` → `SessionSet`. This is recorded history.

`WorkoutSession.init(from: Workout)` implements **copy-on-start**: it deep-copies the template into value snapshots — `SessionExercise` stores a `name: String`, never a reference to `Exercise`. Renaming or deleting a library exercise, or editing a workout, therefore can never rewrite past sessions. Do not introduce a relationship from the session side back to the template side; it would defeat this.

Other cross-cutting rules:

- **Ordering**: SwiftData relationships are unordered. Every child model carries an explicit `orderIndex: Int`, exposed through `orderedExercises` / `orderedSets` computed helpers. `orderIndex` also doubles as the displayed set number, so it must stay contiguous from 0 — re-pack it after deletions.
- **Deleting a library `Exercise` cascades** through `Exercise.usages`, removing it from every workout that used it. History is unaffected (snapshots). The UI confirms first when `!usages.isEmpty`.
- **Session lifecycle**: a session is inserted into the store the moment it starts, so `finishedAt == nil` means in progress. Finishing is explicit; `ContentView.deleteAbandonedSessions()` purges unfinished sessions at launch, and `HistoryListView` filters on `finishedAt != nil`.
- **Active session state** lives in `ContentView` as `@State private var activeSession: WorkoutSession?`, presented via `.fullScreenCover(item:)`. `ActiveSessionView` exits through `@Environment(\.dismiss)`, which clears the binding.
- **Numeric input** uses `TextField(value:format: .number)` rather than string binding, which gets locale-correct decimal separators for free.

## SwiftData mechanics

`LightWeightApp.swift` builds a single app-wide `ModelContainer` from an explicit `Schema([...])` and injects it via `.modelContainer(_:)`. **New `@Model` types must be added to that `Schema` array** or they will not be persisted or queryable.

Persistence is on-disk (`isStoredInMemoryOnly: false`) and container creation `fatalError`s on failure, so a schema change that is not migration-compatible will crash on launch. During development, run `xcrun simctl uninstall booted sebis.LightWeight` after changing model shape; there are no migration plans yet.

Views obtain data through `@Query`, mutate through `@Environment(\.modelContext)`, and bind to individual models with `@Bindable`. SwiftUI previews use `.modelContainer(for:inMemory: true)` so they never touch the on-disk store.

To inspect the real store, find the container and open it with `sqlite3`:

```bash
find ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application \
  -name default.store -path "*Application Support*" 2>/dev/null
```

## Deployment target

`IPHONEOS_DEPLOYMENT_TARGET = 26.5` with `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone and iPad). There is no back-deployment concern — current-generation SwiftUI and SwiftData APIs can be used without availability checks.
