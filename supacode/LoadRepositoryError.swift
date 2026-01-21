import Foundation

struct LoadRepositoryError: Identifiable, Hashable {
  let id: UUID
  let title: String
  let message: String
}
