//
//  SessionDetailView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

/// Read-only view of a finished session.
struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                LabeledContent("Started", value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let finishedAt = session.finishedAt {
                    LabeledContent("Finished", value: finishedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }

            ForEach(session.orderedExercises) { sessionExercise in
                Section(sessionExercise.name) {
                    ForEach(sessionExercise.orderedSets) { sessionSet in
                        HStack {
                            Image(systemName: sessionSet.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(sessionSet.isCompleted ? Color.green : Color.secondary)
                            Text("Set \(sessionSet.orderIndex + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(sessionSet.weight.formatted()) kg × \(sessionSet.reps)")
                        }
                    }
                }
            }
        }
        .navigationTitle(session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
