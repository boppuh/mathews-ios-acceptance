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
  @State private var eventSinkValue: String?
  @State private var responseSignal: String?

  private let logger = Logger(
    subsystem: "com.mathewstechnologies.mathews-ios-acceptance",
    category: "task"
  )
  private let testEventSinkEnabled =
    ProcessInfo.processInfo.environment["MATHEWS_TEST_EVENT_SINK"] == "accessibility"

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        Text("Mathews Acceptance")
          .font(.largeTitle.bold())

        Text(fixtureTitle)
          .font(.title2)
          .accessibilityIdentifier("task.title")

        Text("Deterministic fixture account")
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("account.recipe")

        if completed, let responseSignal {
          Label("Task completed", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .accessibilityIdentifier("task.completed")

          Text(responseSignal)
            .accessibilityIdentifier("task.created.response")
        } else {
          Button("Run primary journey") {
            Task {
              guard let response = try? await createTask(),
                response == JourneyResponse(method: "POST", statusCode: 201)
              else {
                return
              }
              responseSignal = "\(response.method) task.created \(response.statusCode)"
              completed = true
              record(event: "task.completed")
            }
          }
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("task.run")
        }

        if let eventSinkValue {
          Text(eventSinkValue)
            .accessibilityIdentifier("test.event-sink")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .navigationTitle("Release gate")
    }
  }

  private func createTask() async throws -> JourneyResponse {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [AcceptanceURLProtocol.self]
    var request = URLRequest(url: URL(string: "https://acceptance.invalid/tasks")!)
    request.httpMethod = "POST"
    let (_, response) = try await URLSession(configuration: configuration).data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    return JourneyResponse(method: request.httpMethod ?? "", statusCode: response.statusCode)
  }

  private func record(event: String) {
    logger.notice("\(event, privacy: .public)")
    if testEventSinkEnabled {
      eventSinkValue = event
    }
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
    guard request.httpMethod == "POST", let url = request.url,
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
