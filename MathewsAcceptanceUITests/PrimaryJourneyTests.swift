import CryptoKit
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
    let accountSignal = app.staticTexts["account.authenticated"]
    XCTAssertTrue(accountSignal.waitForExistence(timeout: 5))
    XCTAssertEqual(accountSignal.label, "Authenticated primary account")
    XCTAssertEqual(app.state, .runningForeground)
  }

  private func decodeFixture<Value: Decodable>(_ name: String) throws -> Value {
    let fixture: (base64: String, digest: String) =
      switch name {
      case "primary.json":
        (
          "ewogICJmaXh0dXJlX2lkIjogInByaW1hcnlfZml4dHVyZSIsCiAgImZpeHR1cmVfdmVyc2lvbiI6IDEsCiAgInNjaGVtYV92ZXJzaW9uIjogMSwKICAidmFsdWVzIjogewogICAgInRhc2sudGl0bGUiOiAiUHJlcGFyZSBNVlAgcmVsZWFzZSIKICB9Cn0K",
          "c799658e413345b176cabf11b6206774efd3b3b9d140b0823d06ea7af545b36d"
        )
      case "primary-account.json":
        (
          "ewogICJjcmVkZW50aWFsX3NvdXJjZSI6ICJPUEFRVUVfU0VDUkVUX1JFRkVSRU5DRSIsCiAgInJlY2lwZV9pZCI6ICJwcmltYXJ5X2FjY291bnQiLAogICJyZWNpcGVfdmVyc2lvbiI6IDEsCiAgInNjaGVtYV92ZXJzaW9uIjogMQp9Cg==",
          "faceb89ac7da966aa5be1c5ab05616fd7523e435e22c38bde8260d3790d65acc"
        )
      default:
        throw FixtureError.unknownFixture
      }
    guard let data = Data(base64Encoded: fixture.base64) else {
      throw FixtureError.invalidEncoding
    }
    let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    guard digest == fixture.digest else {
      throw FixtureError.digestMismatch
    }
    return try JSONDecoder().decode(Value.self, from: data)
  }
}

private enum FixtureError: Error {
  case digestMismatch
  case invalidEncoding
  case unknownFixture
}
