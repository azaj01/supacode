import SwiftUI

struct ArchivedWorktreesDetailView: View {
  var body: some View {
    ContentUnavailableView(
      "Archived Worktrees",
      systemImage: "archivebox",
      description: Text("Archived worktrees will appear here")
    )
  }
}
