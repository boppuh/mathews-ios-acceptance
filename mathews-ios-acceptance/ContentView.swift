//
//  ContentView.swift
//  mathews-ios-acceptance
//
//  Created by Ryan Mathews on 8/12/26.
//

import OSLog
import SwiftUI

struct ContentView: View {
  private let fixtureTitle =
    ProcessInfo.processInfo.environment["MATHEWS_TASK_TITLE"]
    ?? "Prepare MVP release"
  @State private var completed = false
  @State private var responseSignal: String?
  @State private var authenticatedAccount: String?

  private let logger = Logger(
    subsystem: "com.mathewstechnologies.mathews-ios-acceptance",
    category: "task"
  )

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        Text("Mathews Acceptance")
          .font(.largeTitle.bold())

        Text(fixtureTitle)
          .font(.title2)
          .accessibilityIdentifier("task.title")

        Text("Opaque fixture account")
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("account.recipe")

        if completed, let responseSignal {
          Label("Task completed", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .accessibilityIdentifier("task.completed")

          Text(responseSignal)
            .accessibilityIdentifier("task.created.response")

          if let authenticatedAccount {
            Text(authenticatedAccount)
              .accessibilityIdentifier("account.authenticated")
          }
        } else {
          Button("Run primary journey") {
            Task {
              guard let accountCredential = try? loadAccountCredential(),
                let response = try? await createTask(accountCredential: accountCredential),
                response == JourneyResponse(method: "POST", statusCode: 201)
              else {
                return
              }
              responseSignal = "\(response.method) task.created \(response.statusCode)"
              authenticatedAccount = "Authenticated primary account"
              completed = true
              record(event: "task.completed")
            }
          }
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("task.run")
        }

      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .navigationTitle("Release gate")
    }
  }

  private func createTask(accountCredential: String) async throws -> JourneyResponse {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [AcceptanceURLProtocol.self]
    var request = URLRequest(url: URL(string: "https://acceptance.invalid/tasks")!)
    request.httpMethod = "POST"
    request.setValue(accountCredential, forHTTPHeaderField: "X-Mathews-Test-Account")
    let (_, response) = try await URLSession(configuration: configuration).data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    return JourneyResponse(method: request.httpMethod ?? "", statusCode: response.statusCode)
  }

  private func loadAccountCredential() throws -> String {
    let documents = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
    let credential = try String(
      contentsOf: documents.appendingPathComponent("mathews-test-account"),
      encoding: .utf8
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !credential.isEmpty else {
      throw URLError(.userAuthenticationRequired)
    }
    return credential
  }

  private func record(event: String) {
    logger.notice("\(event, privacy: .public)")
  }
}

private struct JourneyResponse: Equatable {
  let method: String
  let statusCode: Int
}

private final class AcceptanceURLProtocol: URLProtocol, @unchecked Sendable {
  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "acceptance.invalid"
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard request.httpMethod == "POST",
      request.value(forHTTPHeaderField: "X-Mathews-Test-Account")?.isEmpty == false,
      let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: 201,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
      )
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data("{}".utf8))
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

#Preview {
  ContentView()
}
