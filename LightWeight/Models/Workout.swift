//
//  Workout.swift
//  LightWeight
//

import Foundation
import SwiftData

/// A workout template: an ordered list of exercises, each with planned sets.
@Model
final class Workout {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }

    /// SwiftData relationships are unordered, so ordering always goes through `orderIndex`.
    var orderedExercises: [WorkoutExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// One exercise's slot within a workout template.
@Model
final class WorkoutExercise {
    var orderIndex: Int
    var exercise: Exercise?
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \PlannedSet.workoutExercise)
    var sets: [PlannedSet] = []

    init(exercise: Exercise?, orderIndex: Int) {
        self.exercise = exercise
        self.orderIndex = orderIndex
    }

    var name: String {
        exercise?.name ?? "Exercise"
    }

    var orderedSets: [PlannedSet] {
        sets.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// Planned target values for a single set in a template.
@Model
final class PlannedSet {
    var orderIndex: Int
    var targetWeight: Double
    var targetReps: Int
    var workoutExercise: WorkoutExercise?

    init(orderIndex: Int, targetWeight: Double = 0, targetReps: Int = 0) {
        self.orderIndex = orderIndex
        self.targetWeight = targetWeight
        self.targetReps = targetReps
    }
}
