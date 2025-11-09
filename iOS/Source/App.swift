import SwiftUI

@main
struct ForkfolioApp: App {
    @StateObject private var repository = InMemoryRepository()
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(repository)
        }
    }
}
