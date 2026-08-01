//
//  ActiveSessionView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

/// The live workout. Sets arrive pre-filled with the planned targets; the user overwrites
/// them with what they actually lifted and checks each set off.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession

    @State private var isConfirmingDiscard = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(session.orderedExercises) { sessionExercise in
                    Section(sessionExercise.name) {
                        ForEach(sessionExercise.orderedSets) { sessionSet in
                            SessionSetRow(sessionSet: sessionSet)
                        }
                    }
                }
            }
            .navigationTitle(session.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        isConfirmingDiscard = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") { finish() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Discard this workout?",
                isPresented: $isConfirmingDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) { discard() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Nothing from this session will be saved.")
            }
        }
        .interactiveDismissDisabled()
    }

    private func finish() {
        session.finishedAt = .now
        dismiss()
    }

    private func discard() {
        modelContext.delete(session)
        dismiss()
    }
}

/// One logged set: completion toggle plus the actual weight and reps.
private struct SessionSetRow: View {
    @Bindable var sessionSet: SessionSet

    var body: some View {
        HStack {
            Button {
                sessionSet.isCompleted.toggle()
            } label: {
                Image(systemName: sessionSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(sessionSet.isCompleted ? Color.green : Color.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text("Set \(sessionSet.orderIndex + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)

            TextField("0", value: $sessionSet.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("kg")
                .foregroundStyle(.secondary)

            TextField("0", value: $sessionSet.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
            Text("reps")
                .foregroundStyle(.secondary)
        }
    }
}
