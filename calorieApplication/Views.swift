//
//  Views.swift
//  calorieApplication
//
//  SwiftUI views for dashboard, history, and weight tracking.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = CalorieDataStore()

    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "gauge")
                    Text("Dashboard")
                }

            HistoryView()
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("History")
                }

            WeightTrackerView()
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "scalemass")
                    Text("Weight")
                }
        }
        .preferredColorScheme(.dark)
        .accentColor(.green)
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var store: CalorieDataStore
    @State private var showingAddMeal = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                mainSummaryCard
                macroProgressRow
                todayMealsList
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitle("Today", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Targets & Settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                TargetsSettingsView()
                    .environmentObject(store)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var mainSummaryCard: some View {
        VStack(spacing: 12) {
            Text("Calories Remaining")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("\(store.caloriesRemainingToday)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.green)

            Text("Target \(store.dailyCalorieTarget) • Consumed \(store.todayTotalCalories)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(16)
    }

    private var macroProgressRow: some View {
        VStack(spacing: 16) {
            macroRow(
                label: "Protein",
                consumed: store.todayTotalProtein,
                target: store.dailyProteinTarget,
                color: .blue
            )
            macroRow(
                label: "Fat",
                consumed: store.todayTotalFat,
                target: store.dailyFatTarget,
                color: .orange
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.10))
        .cornerRadius(16)
    }

    private func macroRow(label: String, consumed: Int, target: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(consumed)/\(target) g")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            ProgressView(value: target > 0 ? Double(consumed) / Double(target) : 0)
                .tint(color)
        }
    }

    private var todayMealsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddMeal = true }) {
                    Text("Add Meal")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            if store.todaysMeals.isEmpty {
                Text("No meals logged yet.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            } else {
                List {
                    ForEach(store.todaysMeals) { meal in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.category.rawValue)
                                    .font(.subheadline)
                                Text("\(meal.calories) kcal • P \(meal.protein)g • F \(meal.fat)g")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color(white: 0.08))
                    }
                    .onDelete { indices in
                        indices.map { store.todaysMeals[$0] }.forEach { store.deleteMeal($0) }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 260)
                .background(Color.clear)
            }
        }
    }
}

// MARK: - Add Meal Sheet

struct AddMealView: View {
    @EnvironmentObject var store: CalorieDataStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedCategory: MealCategory = .breakfast
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var fatText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MealCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section(header: Text("Macros")) {
                    TextField("Calories (kcal)", text: $caloriesText)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $proteinText)
                        .keyboardType(.numberPad)
                    TextField("Fat (g)", text: $fatText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationBarTitle("Add Meal", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save", action: saveMeal)
                    .disabled(!canSave)
            )
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool {
        Int(caloriesText) != nil && Int(proteinText) != nil && Int(fatText) != nil
    }

    private func saveMeal() {
        guard let calories = Int(caloriesText),
              let protein = Int(proteinText),
              let fat = Int(fatText) else { return }

        store.addMeal(category: selectedCategory, calories: calories, protein: protein, fat: fat)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Targets / Settings

struct TargetsSettingsView: View {
    @EnvironmentObject var store: CalorieDataStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var calorieTargetText: String = ""
    @State private var proteinTargetText: String = ""
    @State private var fatTargetText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Targets")) {
                    TextField("Calories (kcal)", text: $calorieTargetText)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $proteinTargetText)
                        .keyboardType(.numberPad)
                    TextField("Fat (g)", text: $fatTargetText)
                        .keyboardType(.numberPad)
                }

                Section(footer: Text("These targets are stored locally on this device and used for progress calculations on the dashboard.")) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Targets", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTargets()
                }
                .disabled(!canSave)
            )
        }
        .onAppear(perform: loadFromStore)
        .preferredColorScheme(.dark)
    }

    private func loadFromStore() {
        calorieTargetText = String(store.dailyCalorieTarget)
        proteinTargetText = String(store.dailyProteinTarget)
        fatTargetText = String(store.dailyFatTarget)
    }

    private var canSave: Bool {
        Int(calorieTargetText) != nil &&
        Int(proteinTargetText) != nil &&
        Int(fatTargetText) != nil
    }

    private func saveTargets() {
        guard
            let calories = Int(calorieTargetText),
            let protein = Int(proteinTargetText),
            let fat = Int(fatTargetText)
        else { return }

        store.updateDailyTargets(calories: calories, protein: protein, fat: fat)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - History

struct HistoryView: View {
    @EnvironmentObject var store: CalorieDataStore

    private var monthFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }

    var body: some View {
        NavigationView {
            List {
                if store.recentSummaries.isEmpty {
                    Text("No history yet. Your daily totals will be archived automatically at the end of each day.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 16)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.recentSummaries) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(monthFormatter.string(from: summary.date))
                                    .font(.subheadline)
                                Text("\(summary.totalCalories) kcal")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                                Text("P \(summary.totalProtein)g • F \(summary.totalFat)g")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color(white: 0.08))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitle("Calorie History", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Weight Tracker

struct WeightTrackerView: View {
    @EnvironmentObject var store: CalorieDataStore

    @State private var weightText: String = ""

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    TextField("Current weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Log") {
                        addWeight()
                    }
                    .disabled(Double(weightText) == nil)
                }
                .padding()

                List {
                    if store.weightEntries.isEmpty {
                        Text("No weight entries yet.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 16)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.weightEntries.sorted { $0.date > $1.date }) { entry in
                            HStack {
                                Text(dateFormatter.string(from: entry.date))
                                Spacer()
                                Text(String(format: "%.1f", entry.weight))
                                    .foregroundColor(.green)
                            }
                            .listRowBackground(Color(white: 0.08))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitle("Weight Tracker", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func addWeight() {
        guard let weight = Double(weightText) else { return }
        store.addWeightEntry(weight: weight)
        weightText = ""
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


