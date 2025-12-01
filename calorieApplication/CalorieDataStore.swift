//
//  CalorieDataStore.swift
//  calorieApplication
//
//  Observable data store handling meals, daily summaries, and weight entries.
//

import Foundation
import Combine

final class CalorieDataStore: ObservableObject {
    // MARK: - Published State

    @Published private(set) var todaysMeals: [Meal] = []
    @Published private(set) var daySummaries: [DaySummary] = []
    @Published private(set) var weightEntries: [WeightEntry] = []

    // Daily targets for dashboard (user-adjustable if desired)
    @Published var dailyCalorieTarget: Int = 2000
    @Published var dailyProteinTarget: Int = 150
    @Published var dailyFatTarget: Int = 70

    // MARK: - Keys & Date

    private enum Keys {
        static let todaysMeals = "todaysMeals"
        static let daySummaries = "daySummaries"
        static let weightEntries = "weightEntries"
        static let lastActiveDate = "lastActiveDate"
        static let dailyCalorieTarget = "dailyCalorieTarget"
        static let dailyProteinTarget = "dailyProteinTarget"
        static let dailyFatTarget = "dailyFatTarget"
    }

    private let userDefaults: UserDefaults
    private let calendar = Calendar.current

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
        handlePotentialDayRollover()
    }

    // MARK: - Computed Totals

    var todayTotalCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }

    var todayTotalProtein: Int {
        todaysMeals.reduce(0) { $0 + $1.protein }
    }

    var todayTotalFat: Int {
        todaysMeals.reduce(0) { $0 + $1.fat }
    }

    var caloriesRemainingToday: Int {
        max(dailyCalorieTarget - todayTotalCalories, 0)
    }

    // MARK: - Public API

    func updateDailyTargets(calories: Int, protein: Int, fat: Int) {
        dailyCalorieTarget = calories
        dailyProteinTarget = protein
        dailyFatTarget = fat
        persist()
    }

    func addMeal(category: MealCategory, calories: Int, protein: Int, fat: Int) {
        ensureCurrentDay()
        let meal = Meal(category: category, calories: calories, protein: protein, fat: fat)
        todaysMeals.append(meal)
        persist()
    }

    func deleteMeal(_ meal: Meal) {
        todaysMeals.removeAll { $0.id == meal.id }
        persist()
    }

    func addWeightEntry(weight: Double, date: Date = Date()) {
        let entry = WeightEntry(date: date, weight: weight)
        weightEntries.append(entry)
        weightEntries.sort { $0.date < $1.date }
        persist()
    }

    /// Returns daily summaries for the last year (365 days).
    var recentSummaries: [DaySummary] {
        guard let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: Date()) else {
            return daySummaries
        }
        return daySummaries.filter { $0.date >= oneYearAgo }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Day Rollover & Archiving

    private func handlePotentialDayRollover() {
        guard let lastActive = userDefaults.object(forKey: Keys.lastActiveDate) as? Date else {
            userDefaults.set(Date(), forKey: Keys.lastActiveDate)
            return
        }

        if !calendar.isDate(lastActive, inSameDayAs: Date()) {
            archiveCurrentDayIfNeeded()
            userDefaults.set(Date(), forKey: Keys.lastActiveDate)
        }
    }

    /// Ensures the in-memory "today" state actually refers to the current calendar day.
    private func ensureCurrentDay() {
        handlePotentialDayRollover()
    }

    private func archiveCurrentDayIfNeeded() {
        guard !todaysMeals.isEmpty else { return }

        let totalCalories = todayTotalCalories
        let totalProtein = todayTotalProtein
        let totalFat = todayTotalFat

        // Archive using the previous calendar day if lastActiveDate exists, else today.
        let archiveDate = (userDefaults.object(forKey: Keys.lastActiveDate) as? Date) ?? Date()

        let summary = DaySummary(
            date: archiveDate,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalFat: totalFat
        )

        daySummaries.append(summary)
        todaysMeals.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func load() {
        if let data = userDefaults.data(forKey: Keys.todaysMeals) {
            todaysMeals = (try? JSONDecoder().decode([Meal].self, from: data)) ?? []
        }
        if let data = userDefaults.data(forKey: Keys.daySummaries) {
            daySummaries = (try? JSONDecoder().decode([DaySummary].self, from: data)) ?? []
        }
        if let data = userDefaults.data(forKey: Keys.weightEntries) {
            weightEntries = (try? JSONDecoder().decode([WeightEntry].self, from: data)) ?? []
        }
        if let value = userDefaults.value(forKey: Keys.dailyCalorieTarget) as? Int {
            dailyCalorieTarget = value
        }
        if let value = userDefaults.value(forKey: Keys.dailyProteinTarget) as? Int {
            dailyProteinTarget = value
        }
        if let value = userDefaults.value(forKey: Keys.dailyFatTarget) as? Int {
            dailyFatTarget = value
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(todaysMeals) {
            userDefaults.set(data, forKey: Keys.todaysMeals)
        }
        if let data = try? JSONEncoder().encode(daySummaries) {
            userDefaults.set(data, forKey: Keys.daySummaries)
        }
        if let data = try? JSONEncoder().encode(weightEntries) {
            userDefaults.set(data, forKey: Keys.weightEntries)
        }

        userDefaults.set(dailyCalorieTarget, forKey: Keys.dailyCalorieTarget)
        userDefaults.set(dailyProteinTarget, forKey: Keys.dailyProteinTarget)
        userDefaults.set(dailyFatTarget, forKey: Keys.dailyFatTarget)

        userDefaults.set(Date(), forKey: Keys.lastActiveDate)
    }
}


