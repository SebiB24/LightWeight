//
//  Exercise.swift
//  LightWeight
//

import Foundation
import SwiftData

/// A shared library exercise. Created once, reused across any number of workouts.
@Model
final class Exercise {
    var name: String
    var createdAt: Date

    /// Every workout slot referencing this exercise. Cascading here means deleting a
    /// library exercise also removes it from the workouts that used it.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)
    var usages: [WorkoutExercise] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
