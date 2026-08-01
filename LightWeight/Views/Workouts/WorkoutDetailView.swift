//
//  WorkoutDetailView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

/// Template editor: add exercises to a workout and plan each set's target weight/reps.
struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workout: Workout
    @Binding var activeSession: WorkoutSession?

    @State private var isPickingExercise = false

    var body: some View {
        List {
            ForEach(workout.orderedExercises) { workoutExercise in
                Section {
                    ForEach(workoutExercise.orderedSets) { plannedSet in
                        PlannedSetRow(plannedSet: plannedSet)
                    }
                    .onDelete { offsets in
                        deleteSets(at: offsets, in: workoutExercise)
                    }

                    Button("Add Set") {
                        addSet(to: workoutExercise)
                    }
                } header: {
                    HStack {
                        Text(workoutExercise.name)
                        Spacer()
                        Menu {
                            Button("Remove Exercise", role: .destructive) {
                                removeExercise(workoutExercise)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if workout.exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "plus.circle",
                    description: Text("Add an exercise to start planning this workout.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPickingExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                startWorkout()
            } label: {
                Text("Start Workout")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(workout.exercises.isEmpty)
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $isPickingExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: workout.exercises.count
        )
        workoutExercise.workout = workout
        modelContext.insert(workoutExercise)
    }

    private func removeExercise(_ workoutExercise: WorkoutExercise) {
        modelContext.delete(workoutExercise)
        repackExerciseIndices()
    }

    private func addSet(to workoutExercise: WorkoutExercise) {
        // Copying the previous set's values is the common case when planning.
        let previous = workoutExercise.orderedSets.last
        let plannedSet = PlannedSet(
            orderIndex: workoutExercise.sets.count,
            targetWeight: previous?.targetWeight ?? 0,
            targetReps: previous?.targetReps ?? 0
        )
        plannedSet.workoutExercise = workoutExercise
        modelContext.insert(plannedSet)
    }

    private func deleteSets(at offsets: IndexSet, in workoutExercise: WorkoutExercise) {
        let ordered = workoutExercise.orderedSets
        for index in offsets {
            modelContext.delete(ordered[index])
        }
        repackSetIndices(in: workoutExercise, deleting: offsets)
    }

    /// `orderIndex` doubles as the displayed set number, so it must stay contiguous.
    private func repackSetIndices(in workoutExercise: WorkoutExercise, deleting offsets: IndexSet) {
        let remaining = workoutExercise.orderedSets
            .enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)
        for (position, plannedSet) in remaining.enumerated() {
            plannedSet.orderIndex = position
        }
    }

    private func repackExerciseIndices() {
        for (position, workoutExercise) in workout.orderedExercises.enumerated() {
            workoutExercise.orderIndex = position
        }
    }

    private func startWorkout() {
        let session = WorkoutSession(from: workout)
        modelContext.insert(session)
        activeSession = session
    }
}

/// One planned set: target weight and reps.
private struct PlannedSetRow: View {
    @Bindable var plannedSet: PlannedSet

    var body: some View {
        HStack {
            Text("Set \(plannedSet.orderIndex + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            // `value:format:` gives locale-correct decimal separators for free.
            TextField("0", value: $plannedSet.targetWeight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("kg")
                .foregroundStyle(.secondary)

            TextField("0", value: $plannedSet.targetReps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
            Text("reps")
                .foregroundStyle(.secondary)
        }
    }
}
