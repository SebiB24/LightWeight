//
//  LightWeightApp.swift
//  LightWeight
//
//  Created by Buda Sebastian on 02/08/2026.
//

import SwiftUI
import SwiftData

@main
struct LightWeightApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            PlannedSet.self,
            WorkoutSession.self,
            SessionExercise.self,
            SessionSet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
