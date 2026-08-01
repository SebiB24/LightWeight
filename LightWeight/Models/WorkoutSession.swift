//
//  WorkoutSession.swift
//  LightWeight
//

import Foundation
import SwiftData

/// A performed workout.
///
/// Sessions deliberately store *copies* of the template's names and numbers rather than
/// references back to `Workout`/`Exercise`. Editing or deleting a template later can
/// therefore never rewrite history.
@Model
final class WorkoutSession {
    var workoutName: String
    var startedAt: Date
    /// `nil` while the session is in progress. History only ever shows finished sessions.
    var finishedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(workoutName: String, startedAt: Date = .now) {
        self.workoutName = workoutName
        self.startedAt = startedAt
    }

    /// Copy-on-start: deep-copies the template so the session is self-contained from the
    /// moment it begins, pre-filled with the planned weight/reps for the user to adjust.
    init(from workout: Workout) {
        self.workoutName = workout.name
        self.startedAt = .now
        self.exercises = workout.orderedExercises.map { workoutExercise in
            let sessionExercise = SessionExercise(
                name: workoutExercise.name,
                orderIndex: workoutExercise.orderIndex
            )
            sessionExercise.sets = workoutExercise.orderedSets.map { plannedSet in
                SessionSet(
                    orderIndex: plannedSet.orderIndex,
                    weight: plannedSet.targetWeight,
                    reps: plannedSet.targetReps
                )
            }
            return sessionExercise
        }
    }

    var isInProgress: Bool {
        finishedAt == nil
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// A snapshot of one exercise as performed in a session.
@Model
final class SessionExercise {
    /// Snapshotted name, not a reference — survives renaming or deleting the library exercise.
    var name: String
    var orderIndex: Int
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sets: [SessionSet] = []

    init(name: String, orderIndex: Int) {
        self.name = name
        self.orderIndex = orderIndex
    }

    var orderedSets: [SessionSet] {
        sets.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// What the user actually lifted for a single set.
@Model
final class SessionSet {
    var orderIndex: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var sessionExercise: SessionExercise?

    init(orderIndex: Int, weight: Double, reps: Int, isCompleted: Bool = false) {
        self.orderIndex = orderIndex
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }
}
