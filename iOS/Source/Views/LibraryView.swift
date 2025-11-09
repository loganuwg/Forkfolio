import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var repository: CoreDataRepository
    @StateObject private var vm = LibraryViewModel()
    @State private var showingImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Group {
                if vm.results.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text("No recipes yet").font(.headline)
                        Text("Tap + to add a recipe or paste a URL.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
                } else {
                    List {
                        ForEach(vm.results) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title).font(.headline)
                                    if let creator = recipe.creator { Text(creator.name).font(.subheadline).foregroundStyle(.secondary) }
                                    if !recipe.tags.isEmpty { Text(recipe.tags.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Forkfolio")
            .toolbar {
                NavigationLink(destination: RecipeEditorView()) {
                    Image(systemName: "plus")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.favoritesOnly.toggle()
                        vm.search()
                    } label: {
                        Image(systemName: vm.favoritesOnly ? "heart.fill" : "heart")
                    }
                    .accessibilityLabel("Toggle favorites")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "tray.and.arrow.down")
                    }
                    .accessibilityLabel("Import recipes")
                }
            }
            .onAppear {
                vm.setRepository(repository)
                vm.search()
            }
            .onChange(of: vm.query) { _ in vm.search() }
            .onChange(of: vm.favoritesOnly) { _ in vm.search() }
            .onReceive(repository.$recipes) { _ in vm.search() }
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search recipes")
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json, .commaSeparatedText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let data = try Data(contentsOf: url)
                        let importer = ImportService()
                        let imported: [Recipe]
                        if url.pathExtension.lowercased() == "json" {
                            imported = (try? importer.importJSON(data: data)) ?? []
                        } else {
                            imported = (try? importer.importCSV(data: data)) ?? []
                        }
                        for r in imported { repository.add(r) }
                        vm.search()
                    } catch {
                        importError = "Failed to import file."
                    }
                case .failure:
                    break
                }
            }
            .alert("Import Error", isPresented: Binding(get: { importError != nil }, set: { _ in importError = nil })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importError ?? "")
            }
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View { LibraryView() }
}
