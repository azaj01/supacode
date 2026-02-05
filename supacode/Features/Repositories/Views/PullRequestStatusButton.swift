import SwiftUI

struct PullRequestStatusTag: Identifiable {
  let id: String
  let text: String
  let color: Color
}

enum PullRequestStatus {
  static func hasConflicts(mergeable: String?, mergeStateStatus: String?) -> Bool {
    let mergeable = mergeable?.uppercased()
    let mergeStateStatus = mergeStateStatus?.uppercased()
    return mergeable == "CONFLICTING" || mergeStateStatus == "DIRTY"
  }

  static func statusTags(
    reviewDecision: String?,
    mergeable: String?,
    mergeStateStatus: String?
  ) -> [PullRequestStatusTag] {
    var statusParts: [PullRequestStatusTag] = []
    if let reviewDecision = reviewDecision?.uppercased() {
      switch reviewDecision {
      case "APPROVED":
        statusParts.append(PullRequestStatusTag(id: "review-approved", text: "Review approved", color: .green))
      case "REVIEW_REQUIRED":
        statusParts.append(PullRequestStatusTag(id: "review-required", text: "Review required", color: .orange))
      case "CHANGES_REQUESTED":
        statusParts.append(PullRequestStatusTag(id: "changes-requested", text: "Changes requested", color: .red))
      default:
        break
      }
    }
    let mergeableUpper = mergeable?.uppercased()
    let mergeStateUpper = mergeStateStatus?.uppercased()
    if hasConflicts(mergeable: mergeable, mergeStateStatus: mergeStateStatus) {
      statusParts.append(PullRequestStatusTag(id: "merge-conflicts", text: "Merge conflicts", color: .red))
    } else if mergeableUpper == "MERGEABLE" || mergeStateUpper == "CLEAN" {
      statusParts.append(PullRequestStatusTag(id: "no-conflicts", text: "No conflicts", color: .green))
    }
    return statusParts
  }
}
