import ComposableArchitecture
import Sharing

struct RepositoryPersistenceClient {
  var loadRoots: @Sendable () async -> [String]
  var saveRoots: @Sendable ([String]) async -> Void
  var loadPinnedWorktreeIDs: @Sendable () async -> [Worktree.ID]
  var savePinnedWorktreeIDs: @Sendable ([Worktree.ID]) async -> Void
}

extension RepositoryPersistenceClient: DependencyKey {
  static let liveValue: RepositoryPersistenceClient = {
    return RepositoryPersistenceClient(
      loadRoots: {
        @Shared(.settingsFile) var settings: SettingsFile
        return settings.repositoryRoots
      },
      saveRoots: { roots in
        @Shared(.settingsFile) var settings: SettingsFile
        $settings.withLock {
          $0.repositoryRoots = roots
        }
      },
      loadPinnedWorktreeIDs: {
        @Shared(.settingsFile) var settings: SettingsFile
        return settings.pinnedWorktreeIDs
      },
      savePinnedWorktreeIDs: { ids in
        @Shared(.settingsFile) var settings: SettingsFile
        $settings.withLock {
          $0.pinnedWorktreeIDs = ids
        }
      }
    )
  }()
  static let testValue = RepositoryPersistenceClient(
    loadRoots: { [] },
    saveRoots: { _ in },
    loadPinnedWorktreeIDs: { [] },
    savePinnedWorktreeIDs: { _ in }
  )
}

extension DependencyValues {
  var repositoryPersistence: RepositoryPersistenceClient {
    get { self[RepositoryPersistenceClient.self] }
    set { self[RepositoryPersistenceClient.self] = newValue }
  }
}
