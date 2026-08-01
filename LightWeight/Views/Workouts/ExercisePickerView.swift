//
//  ExercisePickerView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

/// Sheet for adding an exercise to a workout. Picks from the shared library, and can
/// create a new library exercise inline so the user isn't forced to the Exercises tab.
struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]

    @State private var draftName = ""

    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("New Exercise") {
                    HStack {
                        TextField("Name", text: $draftName)
                        Button("Add") { createAndSelect() }
                            .disabled(trimmedDraft.isEmpty)
                    }
                }

                Section("Library") {
                    if exercises.isEmpty {
                        Text("No exercises yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(exercises) { exercise in
                        Button(exercise.name) {
                            onSelect(exercise)
                            dismiss()
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var trimmedDraft: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createAndSelect() {
        let exercise = Exercise(name: trimmedDraft)
        modelContext.insert(exercise)
        onSelect(exercise)
        dismiss()
    }
}
