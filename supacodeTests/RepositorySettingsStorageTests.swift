import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@testable import supacode

struct RepositorySettingsStorageTests {
  @Test(.dependencies) func loadCreatesDefaultAndPersists() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let repositoryStorage = RepositorySettingsStorage()
    let rootURL = URL(fileURLWithPath: "/tmp/repo")

    let settings = withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      repositoryStorage.load(for: rootURL)
    }

    #expect(settings == RepositorySettings.default)

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let saved = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(
      saved.repositories[rootURL.path(percentEncoded: false)] == RepositorySettings.default
    )
  }

  @Test(.dependencies) func saveOverwritesExistingSettings() throws {
    let storage = SettingsTestStorage()
    let suiteName = "supacode.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let repositoryStorage = RepositorySettingsStorage()
    let rootURL = URL(fileURLWithPath: "/tmp/repo")

    var settings = RepositorySettings.default
    settings.runScript = "echo updated"
    withDependencies {
      $0.settingsFileStorage = storage.storage
      $0.settingsUserDefaults = SettingsUserDefaults(userDefaults: userDefaults)
    } operation: {
      repositoryStorage.save(settings, for: rootURL)
    }

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let reloaded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(reloaded.repositories[rootURL.path(percentEncoded: false)] == settings)
  }
}
