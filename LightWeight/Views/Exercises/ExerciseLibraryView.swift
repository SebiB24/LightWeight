//
//  ExerciseLibraryView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]

    @State private var isAdding = false
    @State private var draftName = ""
    @State private var renamingExercise: Exercise?
    @State private var pendingDeletion: Exercise?

    var body: some View {
        List {
            ForEach(exercises) { exercise in
                Button {
                    draftName = exercise.name
                    renamingExercise = exercise
                } label: {
                    HStack {
                        Text(exercise.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !exercise.usages.isEmpty {
                            Text("\(exercise.usages.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        requestDelete(exercise)
                    }
                }
            }
        }
        .navigationTitle("Exercises")
        .overlay {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "list.bullet",
                    description: Text("Add exercises here, then use them to build workouts.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftName = ""
                    isAdding = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .alert("New Exercise", isPresented: $isAdding) {
            TextField("Name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { addExercise() }
        }
        .alert(
            "Rename Exercise",
            isPresented: Binding(
                get: { renamingExercise != nil },
                set: { if !$0 { renamingExercise = nil } }
            )
        ) {
            TextField("Name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameExercise() }
        }
        .confirmationDialog(
            "Delete Exercise",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { exercise in
            Button("Delete", role: .destructive) { delete(exercise) }
            Button("Cancel", role: .cancel) {}
        } message: { exercise in
            Text("\"\(exercise.name)\" is used in \(exercise.usages.count) workout\(exercise.usages.count == 1 ? "" : "s"). Deleting it removes it from them. Past sessions are not affected.")
        }
    }

    private var trimmedDraft: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addExercise() {
        guard !trimmedDraft.isEmpty else { return }
        modelContext.insert(Exercise(name: trimmedDraft))
        draftName = ""
    }

    private func renameExercise() {
        guard let exercise = renamingExercise, !trimmedDraft.isEmpty else { return }
        exercise.name = trimmedDraft
        renamingExercise = nil
    }

    private func requestDelete(_ exercise: Exercise) {
        if exercise.usages.isEmpty {
            delete(exercise)
        } else {
            pendingDeletion = exercise
        }
    }

    private func delete(_ exercise: Exercise) {
        modelContext.delete(exercise)
        pendingDeletion = nil
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
