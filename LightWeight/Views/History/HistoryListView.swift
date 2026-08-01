//
//  HistoryListView.swift
//  LightWeight
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext

    // Only finished sessions are history; in-progress ones have a nil finishedAt.
    @Query(
        filter: #Predicate<WorkoutSession> { $0.finishedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.workoutName)
                        Text(session.startedAt, format: .dateTime.weekday().day().month().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .navigationTitle("History")
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Finish a workout and it will show up here.")
                )
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

#Preview {
    NavigationStack {
        HistoryListView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
