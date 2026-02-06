import SwiftUI

struct NotificationPopoverView: View {
  let notifications: [WorktreeTerminalNotification]

  var body: some View {
    let count = notifications.count
    let countLabel = count == 1 ? "notification" : "notifications"
    ScrollView {
      VStack(alignment: .leading) {
        Text("Notifications")
          .font(.headline)
        Text("\(count) \(countLabel)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Divider()
        ForEach(notifications) { notification in
          HStack(alignment: .top) {
            Image(systemName: "bell")
              .foregroundStyle(.secondary)
              .accessibilityHidden(true)
            Text(notification.content)
              .lineLimit(2)
          }
          .font(.caption)
        }
      }
      .padding()
    }
    .frame(minWidth: 260, maxWidth: 480, maxHeight: 400)
  }
}
