//
//  Models.swift
//  calorieApplication
//
//  Core data models for the calorie & macro log app.
//

import Foundation

enum MealCategory: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }
}

struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let category: MealCategory
    let calories: Int
    let protein: Int
    let fat: Int

    init(id: UUID = UUID(), date: Date = Date(), category: MealCategory, calories: Int, protein: Int, fat: Int) {
        self.id = id
        self.date = date
        self.category = category
        self.calories = calories
        self.protein = protein
        self.fat = fat
    }
}

struct DaySummary: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalCalories: Int
    let totalProtein: Int
    let totalFat: Int

    init(id: UUID = UUID(), date: Date, totalCalories: Int, totalProtein: Int, totalFat: Int) {
        self.id = id
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalFat = totalFat
    }
}

struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double

    init(id: UUID = UUID(), date: Date, weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}


