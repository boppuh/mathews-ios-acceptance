import Foundation
import XCTest

final class PrimaryJourneyTests: XCTestCase {
  private struct Fixture: Decodable {
    let fixtureID: String
    let fixtureVersion: Int
    let schemaVersion: Int
    let values: [String: String]

    enum CodingKeys: String, CodingKey {
      case fixtureID = "fixture_id"
      case fixtureVersion = "fixture_version"
      case schemaVersion = "schema_version"
      case values
    }
  }

  private struct AccountRecipe: Decodable {
    let credentialSource: String
    let recipeID: String
    let recipeVersion: Int
    let schemaVersion: Int

    enum CodingKeys: String, CodingKey {
      case credentialSource = "credential_source"
      case recipeID = "recipe_id"
      case recipeVersion = "recipe_version"
      case schemaVersion = "schema_version"
    }
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testPrimaryJourney() throws {
    let fixture: Fixture = try decodeFixture("primary.json")
    let account: AccountRecipe = try decodeFixture("primary-account.json")

    XCTAssertEqual(fixture.schemaVersion, 1)
    XCTAssertEqual(fixture.fixtureID, "primary_fixture")
    XCTAssertEqual(fixture.fixtureVersion, 1)
    XCTAssertEqual(account.schemaVersion, 1)
    XCTAssertEqual(account.recipeID, "primary_account")
    XCTAssertEqual(account.recipeVersion, 1)
    XCTAssertEqual(account.credentialSource, "OPAQUE_SECRET_REFERENCE")

    let expectedTitle = try XCTUnwrap(fixture.values["task.title"])
    let app = XCUIApplication(
      bundleIdentifier: "com.mathewstechnologies.mathews-ios-acceptance"
    )
    app.launchEnvironment = [
      "MATHEWS_TASK_TITLE": expectedTitle,
      "TZ": "UTC",
    ]
    app.launchArguments = [
      "-AppleLanguages", "(en_US_POSIX)",
      "-AppleLocale", "en_US_POSIX",
    ]
    app.launch()

    let title = app.staticTexts["task.title"]
    XCTAssertTrue(title.waitForExistence(timeout: 10))
    XCTAssertEqual(title.label, expectedTitle)

    let run = app.buttons["task.run"]
    XCTAssertTrue(run.exists)
    run.tap()

    XCTAssertTrue(app.staticTexts["task.completed"].waitForExistence(timeout: 5))
    let response = app.staticTexts["task.created.response"]
    XCTAssertTrue(response.exists)
    XCTAssertEqual(response.label, "POST task.created 201")
    XCTAssertEqual(app.state, .runningForeground)
  }

  private func decodeFixture<Value: Decodable>(_ name: String) throws -> Value {
    let source = URL(fileURLWithPath: #filePath)
    let fixtureURL =
      source
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures", isDirectory: true)
      .appendingPathComponent(name)
    return try JSONDecoder().decode(Value.self, from: Data(contentsOf: fixtureURL))
  }
}
