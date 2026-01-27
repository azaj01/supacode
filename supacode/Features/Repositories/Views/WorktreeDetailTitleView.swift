import SwiftUI

struct WorktreeDetailTitleView: View {
  let branchName: String
  let runScriptEnabled: Bool
  let runScriptIsRunning: Bool
  let runScriptHelpText: String
  let stopRunScriptHelpText: String
  let runScriptAction: () -> Void
  let stopRunScriptAction: () -> Void
  let onSubmit: (String) -> Void

  @State private var isEditing = false
  @State private var draftName = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    if isEditing {
      HStack(spacing: 6) {
        HStack(spacing: 6) {
          Image(systemName: "arrow.trianglehead.branch")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
          TextField("Branch", text: $draftName)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onChange(of: draftName) { _, newValue in
              let filtered = String(newValue.filter { !$0.isWhitespace })
              if filtered != newValue {
                draftName = filtered
              }
            }
            .onSubmit { commit() }
            .onExitCommand { cancel() }
            .onChange(of: isFocused) { _, isFocused in
              if !isFocused {
                cancel()
              }
            }
        }
        .font(.headline)
        .monospaced()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .task { isFocused = true }
        .help("Rename branch (Return to confirm)")
        if runScriptIsRunning {
          Button("Stop Script", systemImage: "stop.fill") {
            stopRunScriptAction()
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.plain)
          .help(stopRunScriptHelpText)
        } else {
          Button("Run Script", systemImage: "play.fill") {
            runScriptAction()
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.plain)
          .help(runScriptHelpText)
          .disabled(!runScriptEnabled)
        }
      }
    } else {
      HStack(spacing: 6) {
        Button {
          beginEditing()
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "arrow.trianglehead.branch")
              .foregroundStyle(.secondary)
              .accessibilityHidden(true)
            Text(branchName)
          }
          .font(.headline)
          .monospaced()
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .help("Tap to rename branch")
        if runScriptIsRunning {
          Button("Stop Script", systemImage: "stop.fill") {
            stopRunScriptAction()
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.plain)
          .help(stopRunScriptHelpText)
        } else {
          Button("Run Script", systemImage: "play.fill") {
            runScriptAction()
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.plain)
          .help(runScriptHelpText)
          .disabled(!runScriptEnabled)
        }
      }
    }
  }

  private func beginEditing() {
    draftName = branchName
    isEditing = true
  }

  private func cancel() {
    isEditing = false
    draftName = branchName
    isFocused = false
  }

  private func commit() {
    let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    isEditing = false
    isFocused = false
    guard !trimmed.isEmpty else { return }
    if trimmed != branchName {
      onSubmit(trimmed)
    }
  }
}
