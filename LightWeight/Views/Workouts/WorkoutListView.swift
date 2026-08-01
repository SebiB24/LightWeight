//
//  WorkoutListView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.createdAt) private var workouts: [Workout]
    @Binding var activeSession: WorkoutSession?

    @State private var isAdding = false
    @State private var draftName = ""

    var body: some View {
        List {
            ForEach(workouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout, activeSession: $activeSession)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                        Text(exerciseCountLabel(for: workout))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteWorkouts)
        }
        .navigationTitle("Workouts")
        .overlay {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts",
                    systemImage: "dumbbell",
                    description: Text("Create a workout, add exercises and sets, then start it.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftName = ""
                    isAdding = true
                } label: {
                    Label("Add Workout", systemImage: "plus")
                }
            }
        }
        .alert("New Workout", isPresented: $isAdding) {
            TextField("Name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Create") { addWorkout() }
        }
    }

    private func exerciseCountLabel(for workout: Workout) -> String {
        let count = workout.exercises.count
        return count == 1 ? "1 exercise" : "\(count) exercises"
    }

    private func addWorkout() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(Workout(name: name))
        draftName = ""
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutListView(activeSession: .constant(nil))
    }
    .modelContainer(for: Workout.self, inMemory: true)
}
