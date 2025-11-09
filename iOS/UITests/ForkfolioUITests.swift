import XCTest

final class ForkfolioUITests: XCTestCase {
    func testScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UI_SNAPSHOT")
        app.launch()

        // Library screenshot
        take(name: "01-Library", app: app)

        // Open first recipe if it exists
        let firstCell = app.cells.element(boundBy: 0)
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()
            take(name: "02-Detail", app: app)
        }
    }

    private func take(name: String, app: XCUIApplication) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
