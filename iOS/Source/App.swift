import SwiftUI

@main
struct ForkfolioApp: App {
    @StateObject private var repository = CoreDataRepository()
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(repository)
                .tint(Theme.primary)
        }
    }
}
