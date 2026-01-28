import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import Testing

@testable import supacode

struct SettingsFilePersistenceTests {
  @Test(.dependencies) func loadWritesDefaultsWhenMissing() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }

    withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      @Shared(.settingsFile) var settings: SettingsFile
      _ = settings
    }

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded == .default)
  }

  @Test(.dependencies) func saveAndReload() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }

    withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      @Shared(.settingsFile) var settings: SettingsFile
      $settings.withLock {
        $0.global.appearanceMode = .dark
        $0.repositoryRoots = ["/tmp/repo-a", "/tmp/repo-b"]
        $0.pinnedWorktreeIDs = ["/tmp/repo-a/wt-1"]
      }
    }

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded.global.appearanceMode == .dark)
    #expect(decoded.repositoryRoots == ["/tmp/repo-a", "/tmp/repo-b"])
    #expect(decoded.pinnedWorktreeIDs == ["/tmp/repo-a/wt-1"])
  }

  @Test(.dependencies) func invalidJSONResetsToDefaults() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }

    try storage.storage.save(Data("{".utf8), SupacodePaths.settingsURL)

    withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      @Shared(.settingsFile) var settings: SettingsFile
      _ = settings
    }

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded == .default)
  }

  @Test(.dependencies) func migratesOldSettingsWithoutInAppNotificationsEnabled() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }

    let oldSettings = """
      {
        "global": {
          "appearanceMode": "dark",
          "updatesAutomaticallyCheckForUpdates": false,
          "updatesAutomaticallyDownloadUpdates": true
        },
        "repositories": {}
      }
      """
    try storage.storage.save(Data(oldSettings.utf8), SupacodePaths.settingsURL)

    let settings: SettingsFile = withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      @Shared(.settingsFile) var settings: SettingsFile
      return settings
    }

    #expect(settings.global.appearanceMode == .dark)
    #expect(settings.global.updatesAutomaticallyCheckForUpdates == false)
    #expect(settings.global.updatesAutomaticallyDownloadUpdates == true)
    #expect(settings.global.inAppNotificationsEnabled == true)
    #expect(settings.repositoryRoots.isEmpty)
    #expect(settings.pinnedWorktreeIDs.isEmpty)
  }

  @Test(.dependencies) func migratesRepositoryDataFromUserDefaults() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let rootsKey = "repositories.roots"
    let pinnedKey = "repositories.worktrees.pinned"
    let roots = ["/tmp/repo-a", "/tmp/repo-b"]
    let pinned = ["/tmp/repo-a/wt-1"]
    userDefaults.set(try JSONEncoder().encode(roots), forKey: rootsKey)
    userDefaults.set(try JSONEncoder().encode(pinned), forKey: pinnedKey)

    let settings: SettingsFile = withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      @Shared(.settingsFile) var settings: SettingsFile
      return settings
    }

    #expect(settings.repositoryRoots == roots)
    #expect(settings.pinnedWorktreeIDs == pinned)
    #expect(userDefaults.object(forKey: rootsKey) == nil)
    #expect(userDefaults.object(forKey: pinnedKey) == nil)

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded.repositoryRoots == roots)
    #expect(decoded.pinnedWorktreeIDs == pinned)
  }
}
