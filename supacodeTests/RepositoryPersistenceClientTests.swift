import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@testable import supacode

struct RepositoryPersistenceClientTests {
  @Test(.dependencies) func savesAndLoadsRootsAndPins() async throws {
    let storage = SettingsTestStorage()

    var initial = SettingsFile.default
    initial.global.appearanceMode = .dark
    let initialData = try JSONEncoder().encode(initial)
    try storage.storage.save(initialData, SupacodePaths.settingsURL)

    let client = RepositoryPersistenceClient.liveValue
    let result = await withDependencies {
      $0.settingsFileStorage = storage.storage
    } operation: {
      await client.saveRoots([
        "/tmp/repo-a",
        "/tmp/repo-a",
        "/tmp/repo-b/../repo-b",
      ])
      await client.savePinnedWorktreeIDs([
        "/tmp/repo-a/wt-1",
        "/tmp/repo-a/wt-1",
      ])
      let roots = await client.loadRoots()
      let pinned = await client.loadPinnedWorktreeIDs()
      return (roots: roots, pinned: pinned)
    }

    #expect(result.roots == ["/tmp/repo-a", "/tmp/repo-b"])
    #expect(result.pinned == ["/tmp/repo-a/wt-1"])

    let data = try requireData(storage.data(for: SupacodePaths.settingsURL))
    let finalSettings = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(finalSettings.global.appearanceMode == .dark)
  }
}
