import SwiftUI

struct RecipeEditorView: View {
    @EnvironmentObject var repository: CoreDataRepository
    @StateObject private var vm = RecipeEditorViewModel(parsing: ParsingService())

    var body: some View {
        Form {
            Section(header: Text("Basics")) {
                TextField("Title", text: $vm.title)
                TextField("Source URL", text: $vm.sourceURLString)
                HStack { TextField("Creator", text: $vm.creatorName); TextField("Platform", text: $vm.creatorPlatform) }
                TextField("Tags (comma-separated)", text: $vm.tagsText)
                Toggle("Favorite", isOn: $vm.favorite)
                Stepper(value: $vm.rating, in: 0...5) { Text("Rating: \(vm.rating)") }
                HStack { TextField("Prep (min)", value: $vm.prepMinutes, formatter: NumberFormatter()); TextField("Cook (min)", value: $vm.cookMinutes, formatter: NumberFormatter()) }
                TextField("Servings", value: $vm.servings, formatter: NumberFormatter())
                TextField("Notes", text: $vm.notes, axis: .vertical)
                Button("Paste URL & Parse") { Task { await vm.pasteURL() } }
            }
            Section(header: Text("Ingredients")) {
                ForEach(Array(vm.ingredients.enumerated()), id: \.element.id) { idx, ing in
                    TextField("Ingredient", text: Binding(get: { ing.text }, set: { vm.ingredients[idx].text = $0 }))
                }
                Button("Add Ingredient") { vm.ingredients.append(Ingredient(text: "")) }
            }
            Section(header: Text("Steps")) {
                ForEach(Array(vm.steps.enumerated()), id: \.element.id) { idx, step in
                    TextField("Step", text: Binding(get: { step.text }, set: { vm.steps[idx].text = $0 }))
                }
                Button("Add Step") { let order = (vm.steps.map { $0.order }.max() ?? 0) + 1; vm.steps.append(Step(order: order, text: "")) }
            }
            Button("Save") { vm.save() }
        }
        .navigationTitle("Add Recipe")
        .onAppear {
            // rebind to env repository when available
            vm.setRepository(repository)
        }
    }
}

struct RecipeEditorView_Previews: PreviewProvider {
    static var previews: some View { RecipeEditorView() }
}
