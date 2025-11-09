import SwiftUI

@main
struct ForkfolioApp: App {
    @StateObject private var repository = CoreDataRepository()
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(repository)
                .tint(Theme.primary)
                .onAppear { seedForSnapshotsIfNeeded() }
        }
    }

    private func seedForSnapshotsIfNeeded() {
        if !ProcessInfo.processInfo.arguments.contains("UI_SNAPSHOT") { return }
        if !repository.recipes.isEmpty { return }
        let pancakes = Recipe(
            title: "Best Pancakes",
            tags: ["breakfast","american"],
            favorite: true,
            rating: 5,
            prepMinutes: 10,
            cookMinutes: 15,
            servings: 4,
            notes: "Fluffy and quick.",
            ingredients: [
                Ingredient(text: "2 cups flour"),
                Ingredient(text: "1 cup milk"),
                Ingredient(text: "2 eggs")
            ],
            steps: [
                Step(order: 1, text: "Mix ingredients"),
                Step(order: 2, text: "Cook on skillet")
            ]
        )
        let pasta = Recipe(
            title: "Garlic Butter Pasta",
            tags: ["dinner","italian"],
            favorite: false,
            rating: 4,
            prepMinutes: 5,
            cookMinutes: 12,
            servings: 2,
            notes: nil,
            ingredients: [
                Ingredient(text: "200g spaghetti"),
                Ingredient(text: "3 cloves garlic"),
                Ingredient(text: "2 tbsp butter")
            ],
            steps: [
                Step(order: 1, text: "Boil pasta"),
                Step(order: 2, text: "Sauté garlic in butter"),
                Step(order: 3, text: "Combine and serve")
            ]
        )
        repository.add(pancakes)
        repository.add(pasta)
    }
}
