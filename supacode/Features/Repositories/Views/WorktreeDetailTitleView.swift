import SwiftUI

struct WorktreeDetailTitleView: View {
  let branchName: String
  let onSubmit: (String) -> Void

  @State private var isEditing = false
  @State private var draftName = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack {
      if isEditing {
        TextField("Branch", text: $draftName)
          .textFieldStyle(.plain)
          .focused($isFocused)
          .onSubmit { commit() }
          .onExitCommand { cancel() }
          .onChange(of: isFocused) { _, isFocused in
            if !isFocused {
              cancel()
            }
          }
          .help("Switch branch (Return to confirm)")
      } else {
        Button {
          beginEditing()
        } label: {
          Text(branchName)
            .font(.headline)
        }
        .buttonStyle(.plain)
        .help("Change branch (no shortcut)")
      }
      XcodeStyleStatusView()
    }
  }

  private func beginEditing() {
    draftName = branchName
    isEditing = true
    isFocused = true
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
