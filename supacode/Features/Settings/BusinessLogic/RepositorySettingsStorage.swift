import Foundation
import Sharing

nonisolated struct RepositorySettingsStorage {
  func load(for rootURL: URL) -> RepositorySettings {
    let repositoryID = repositoryID(for: rootURL)
    @Shared(.settingsFile) var settingsFile: SettingsFile
    return $settingsFile.withLock { settings in
      if let existing = settings.repositories[repositoryID] {
        return existing
      }
      let defaults = RepositorySettings.default
      settings.repositories[repositoryID] = defaults
      return defaults
    }
  }

  func save(_ settings: RepositorySettings, for rootURL: URL) {
    let repositoryID = repositoryID(for: rootURL)
    @Shared(.settingsFile) var settingsFile: SettingsFile
    $settingsFile.withLock {
      $0.repositories[repositoryID] = settings
    }
  }

  private func repositoryID(for rootURL: URL) -> String {
    rootURL.standardizedFileURL.path(percentEncoded: false)
  }
}
