import SwiftUI

struct PullRequestStatusButton: View {
  let model: PullRequestStatusModel
  @Environment(\.openURL) private var openURL

  var body: some View {
    Button {
      if let url = model.url {
        openURL(url)
      }
    } label: {
      PullRequestBadgeView(
        text: model.badgeText,
        color: model.badgeColor
      )
    }
    .buttonStyle(.plain)
    .help(model.helpText)
  }

}

struct PullRequestStatusModel: Equatable {
  let number: Int
  let state: String
  let url: URL?

  init?(snapshot: WorktreeInfoSnapshot?) {
    guard
      let snapshot,
      let number = snapshot.pullRequestNumber,
      let state = snapshot.pullRequestState?.uppercased(),
      PullRequestBadgeStyle.style(state: state, number: number) != nil
    else {
      return nil
    }
    self.number = number
    self.state = state
    self.url = snapshot.pullRequestURL.flatMap(URL.init(string:))
  }

  var badgeText: String {
    PullRequestBadgeStyle.style(state: state, number: number)?.text ?? "#\(number)"
  }

  var badgeColor: Color {
    PullRequestBadgeStyle.style(state: state, number: number)?.color ?? .secondary
  }

  var helpText: String {
    PullRequestBadgeStyle.helpText(state: state, url: url)
  }
}
