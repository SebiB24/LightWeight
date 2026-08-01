# LightWeight — Fitness Tracker, Iteration 1

## Context

The repo is the unmodified Xcode SwiftUI+SwiftData template (3 files). This iteration turns it into a minimal workout tracker: a shared exercise library, workout templates (exercises + planned sets with target weight/reps), live workout sessions (pre-filled from the plan, log actual weight/reps, check off sets), and saved session history. No images/videos, timers, or stats.

User decisions: **shared exercise library** (create once, pick when building workouts) and **planned weight+reps on template sets** (session starts pre-filled).

## Data model (SwiftData)

Six `@Model` classes in two clusters. The session side stores **value snapshots** (copied names + numbers, no references to templates), so later edits/deletes of templates or library exercises can never corrupt history. SwiftData relationship arrays are unordered, so every child model carries an explicit `orderIndex: Int` with `ordered*` computed sort helpers; re-pack indices after deletes.

**Template side:**
- `Exercise` (`Models/Exercise.swift`) — `name`, `createdAt`; `@Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise) var usages: [WorkoutExercise]`
- `Workout` (`Models/Workout.swift`) — `name`, `createdAt`; cascade → `[WorkoutExercise]` (inverse `\WorkoutExercise.workout`); `orderedExercises` helper
- `WorkoutExercise` (same file) — join object: `orderIndex`, `exercise: Exercise?`, `workout: Workout?`; cascade → `[PlannedSet]`
- `PlannedSet` (same file) — `orderIndex`, `targetWeight: Double`, `targetReps: Int`, `workoutExercise: WorkoutExercise?`

**Session side (copy-on-start):**
- `WorkoutSession` (`Models/WorkoutSession.swift`) — `workoutName: String` (copied), `startedAt`, `finishedAt: Date?` (`nil` = in progress); cascade → `[SessionExercise]`. Convenience `init(from workout: Workout)` deep-copies ordered exercises/sets, pre-filling `weight`/`reps` from targets with `isCompleted = false`.
- `SessionExercise` — `name: String` (snapshot), `orderIndex`, `session: WorkoutSession?`; cascade → `[SessionSet]`
- `SessionSet` — `orderIndex`, `weight: Double`, `reps: Int`, `isCompleted: Bool`, `sessionExercise: SessionExercise?`

**Delete rules:** all parent→child compositions are `.cascade`. Deleting a library `Exercise` cascades its `usages` out of all workouts (confirmation dialog when `!usages.isEmpty`: "Used in N workouts…"). History is untouched (snapshots). Display sites use `exercise?.name ?? "Exercise"`.

**Schema:** in `LightWeightApp.swift` replace the array: `Schema([Exercise.self, Workout.self, WorkoutExercise.self, PlannedSet.self, WorkoutSession.self, SessionExercise.self, SessionSet.self])`. Delete `Item.swift`. Store is on-disk and container creation `fatalError`s → after any schema-shape change, `xcrun simctl uninstall booted sebis.LightWeight` before relaunch (no migration plans in iteration 1).

Note: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — no `@MainActor` annotations anywhere.

## UI / navigation

Rewrite `ContentView.swift`:

```
ContentView
├── @State private var activeSession: WorkoutSession?
├── TabView
│   ├── Workouts  → NavigationStack { WorkoutListView(activeSession: $activeSession) }
│   ├── Exercises → NavigationStack { ExerciseLibraryView() }
│   └── History   → NavigationStack { HistoryListView() }
└── .fullScreenCover(item: $activeSession) { ActiveSessionView(session: $0) }
```

- **WorkoutListView** — `@Query(sort: \Workout.createdAt)`; `+` alert with name TextField; swipe-to-delete; link to detail.
- **WorkoutDetailView(workout:)** — template editor. Section per `WorkoutExercise` (by `orderIndex`); rows = `PlannedSetRow` with weight `TextField(value:format: .number)` + `.decimalPad` and reps + `.numberPad` (locale-correct decimal separator for free). "Add Set" copies the previous set's values (0/0 if first). Swipe-to-delete sets. "Add Exercise" → **ExercisePickerView** sheet (`@Query` library list, tap to append; inline "New Exercise" field so the user isn't forced to the Exercises tab). Prominent **Start Workout** button (disabled when no exercises): insert `WorkoutSession(from: workout)`, set `activeSession`.
- **ExerciseLibraryView** — `@Query` list; `+` alert to create; tap → rename alert; swipe-to-delete with used-in-N-workouts confirmation.
- **ActiveSessionView(session:)** — `fullScreenCover` (session is modal; no accidental swipe-dismiss), own `NavigationStack`. Sections per `SessionExercise`, rows per `SessionSet`: checkmark toggle for `isCompleted`, weight/reps TextFields bound to the model (`@Bindable`), pre-filled by construction. Toolbar: **Finish** (`finishedAt = .now; activeSession = nil`) and **Discard** (confirmation → delete session).
- **HistoryListView** — `@Query(filter: #Predicate<WorkoutSession> { $0.finishedAt != nil }, sort: \.startedAt, order: .reverse)`; swipe-to-delete; link to **SessionDetailView** — read-only mirror: "Set N — 62.5 × 8" + completed indicator.

**Abandoned sessions:** edits autosave live, so killing the app mid-session leaves an unfinished row. On `ContentView` `.task`, fetch sessions with `finishedAt == nil` and delete them (finishing is explicit; History only shows finished). ~5 lines, no UI.

Empty states via `ContentUnavailableView` on all three lists.

## File layout

```
LightWeight/
├── LightWeightApp.swift          (edit: new Schema array)
├── ContentView.swift             (rewrite: TabView + activeSession + cover + cleanup)
├── Item.swift                    (DELETE)
├── Models/
│   ├── Exercise.swift
│   ├── Workout.swift             (Workout, WorkoutExercise, PlannedSet)
│   └── WorkoutSession.swift      (WorkoutSession, SessionExercise, SessionSet)
└── Views/
    ├── Workouts/  WorkoutListView.swift, WorkoutDetailView.swift, ExercisePickerView.swift
    ├── Exercises/ ExerciseLibraryView.swift
    ├── Session/   ActiveSessionView.swift
    └── History/   HistoryListView.swift, SessionDetailView.swift
```

`PBXFileSystemSynchronizedRootGroup` picks up new/deleted files automatically — **never edit project.pbxproj**.

## Implementation order

1. Models (3 files) + delete `Item.swift` + Schema update + stub `ContentView` to an empty `TabView` so it compiles.
2. **Build checkpoint**; `xcrun simctl uninstall booted sebis.LightWeight` to clear the old store.
3. Exercise library screen; wire into TabView; verify CRUD in simulator.
4. Workout templates: list, detail editor, exercise picker; verify persistence across relaunch.
5. Session: ActiveSessionView, `activeSession` + fullScreenCover, Start button, Finish/Discard, abandoned-session cleanup.
6. History: list + detail.
7. Final pass: empty states, `#Preview`s with `.modelContainer(for:…, inMemory: true)`, end-to-end run.

## Verification

Build: `xcodebuild -project LightWeight.xcodeproj -scheme LightWeight -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

Launch: boot simulator, `simctl install booted` the DerivedData .app, `simctl launch booted sebis.LightWeight` (per CLAUDE.md).

End-to-end script: add "Squat"/"Bench Press" to library → create "Push Day" workout with both, 3 sets Squat (100.0×5, verify decimal input), 2 sets Bench → Start → edit a set to 102.5×4, check off sets, leave one unchecked → Finish → History shows session with logged values and completion marks → rename/delete library exercises → history unchanged, template updated → start a session, `simctl terminate`, relaunch → no stale unfinished session. No test target exists (creating one requires Xcode UI), so verification is build + simulator walkthrough.
