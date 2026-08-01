//
//  ContentView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    /// The in-progress session, if any. Presented modally over the whole app.
    @State private var activeSession: WorkoutSession?

    var body: some View {
        TabView {
            Tab("Workouts", systemImage: "dumbbell") {
                NavigationStack {
                    WorkoutListView(activeSession: $activeSession)
                }
            }
            Tab("Exercises", systemImage: "list.bullet") {
                NavigationStack {
                    ExerciseLibraryView()
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryListView()
                }
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            ActiveSessionView(session: session)
        }
        .task {
            deleteAbandonedSessions()
        }
    }

    /// A session is written to the store as soon as it starts, so killing the app mid-workout
    /// leaves an unfinished row behind. Finishing is explicit, so anything unfinished at
    /// launch was abandoned.
    private func deleteAbandonedSessions() {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.finishedAt == nil }
        )
        guard let abandoned = try? modelContext.fetch(descriptor) else { return }
        for session in abandoned {
            modelContext.delete(session)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Workout.self, inMemory: true)
}
