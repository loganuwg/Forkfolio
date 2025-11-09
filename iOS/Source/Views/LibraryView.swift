import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var repository: InMemoryRepository
    @StateObject private var vm = LibraryViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.results) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        VStack(alignment: .leading) {
                            Text(recipe.title).font(.headline)
                            if let creator = recipe.creator { Text(creator.name).font(.subheadline).foregroundStyle(.secondary) }
                            if !recipe.tags.isEmpty { Text(recipe.tags.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            .navigationTitle("Forkfolio")
            .toolbar {
                NavigationLink(destination: RecipeEditorView()) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                vm.setRepository(repository)
                vm.search()
            }
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View { LibraryView() }
}
