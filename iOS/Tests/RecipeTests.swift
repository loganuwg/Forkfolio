import XCTest
@testable import Forkfolio

final class RecipeTests: XCTestCase {
    func testExportTextContainsTitle() throws {
        let recipe = Recipe(title: "Test Title")
        let text = ExportService().toText(recipe)
        XCTAssertTrue(text.contains("Test Title"))
    }
}
