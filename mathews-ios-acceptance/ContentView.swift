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

        Text("Deterministic fixture account")
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("account.recipe")

        if completed {
          Label("Task completed", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .accessibilityIdentifier("task.completed")

          Text("POST task.created 201")
            .accessibilityIdentifier("task.created.response")
        } else {
          Button("Run primary journey") {
            completed = true
            logger.notice("task.completed")
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
}

#Preview {
  ContentView()
}
