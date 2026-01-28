import Dependencies
import Foundation
import Sharing

nonisolated struct SettingsFileStorage: Sendable {
  var load: @Sendable (URL) throws -> Data
  var save: @Sendable (Data, URL) throws -> Void
}

nonisolated enum SettingsFileStorageKey: DependencyKey {
  static var liveValue: SettingsFileStorage {
    SettingsFileStorage(
      load: { try Data(contentsOf: $0) },
      save: { data, url in
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic])
      }
    )
  }
  static var previewValue: SettingsFileStorage { .inMemory() }
  static var testValue: SettingsFileStorage { .inMemory() }
}

extension DependencyValues {
  nonisolated var settingsFileStorage: SettingsFileStorage {
    get { self[SettingsFileStorageKey.self] }
    set { self[SettingsFileStorageKey.self] = newValue }
  }
}

extension SettingsFileStorage {
  nonisolated static func inMemory() -> SettingsFileStorage {
    let storage = InMemorySettingsFileStorage()
    return SettingsFileStorage(
      load: { try storage.load($0) },
      save: { try storage.save($0, $1) }
    )
  }
}

nonisolated enum SettingsFileStorageError: Error {
  case missing
}

nonisolated final class InMemorySettingsFileStorage: @unchecked Sendable {
  private let lock = NSLock()
  private var dataByURL: [URL: Data] = [:]

  func load(_ url: URL) throws -> Data {
    lock.lock()
    defer { lock.unlock() }
    guard let data = dataByURL[url] else {
      throw SettingsFileStorageError.missing
    }
    return data
  }

  func save(_ data: Data, _ url: URL) throws {
    lock.lock()
    defer { lock.unlock() }
    dataByURL[url] = data
  }

}

nonisolated struct SettingsUserDefaults: @unchecked Sendable {
  let userDefaults: UserDefaults

  func data(forKey key: String) -> Data? {
    userDefaults.data(forKey: key)
  }

  func object(forKey key: String) -> Any? {
    userDefaults.object(forKey: key)
  }

  func removeObject(forKey key: String) {
    userDefaults.removeObject(forKey: key)
  }
}

nonisolated enum SettingsUserDefaultsKey: DependencyKey {
  static var liveValue: SettingsUserDefaults { SettingsUserDefaults(userDefaults: .standard) }
  static var previewValue: SettingsUserDefaults {
    SettingsUserDefaults(userDefaults: UserDefaults(suiteName: "supacode.preview") ?? .standard)
  }
  static var testValue: SettingsUserDefaults {
    SettingsUserDefaults(userDefaults: UserDefaults(suiteName: "supacode.tests.\(UUID().uuidString)") ?? .standard)
  }
}

extension DependencyValues {
  nonisolated var settingsUserDefaults: SettingsUserDefaults {
    get { self[SettingsUserDefaultsKey.self] }
    set { self[SettingsUserDefaultsKey.self] = newValue }
  }
}

nonisolated enum SettingsFileMigration {
  private static let rootsKey = "repositories.roots"
  private static let pinnedKey = "repositories.worktrees.pinned"

  static func migrate(from userDefaults: SettingsUserDefaults, initial: SettingsFile) -> SettingsFile? {
    let hasRoots = userDefaults.object(forKey: rootsKey) != nil
    let hasPinned = userDefaults.object(forKey: pinnedKey) != nil
    guard hasRoots || hasPinned else { return nil }

    let decoder = JSONDecoder()
    var settings = initial
    if settings.repositoryRoots.isEmpty,
      let data = userDefaults.data(forKey: rootsKey),
      let roots = try? decoder.decode([String].self, from: data),
      !roots.isEmpty
    {
      settings.repositoryRoots = roots
    }
    if settings.pinnedWorktreeIDs.isEmpty,
      let data = userDefaults.data(forKey: pinnedKey),
      let ids = try? decoder.decode([Worktree.ID].self, from: data),
      !ids.isEmpty
    {
      settings.pinnedWorktreeIDs = ids
    }
    cleanupLegacyKeys(in: userDefaults)
    return settings
  }

  static func cleanupLegacyKeys(in userDefaults: SettingsUserDefaults) {
    if userDefaults.object(forKey: rootsKey) != nil {
      userDefaults.removeObject(forKey: rootsKey)
    }
    if userDefaults.object(forKey: pinnedKey) != nil {
      userDefaults.removeObject(forKey: pinnedKey)
    }
  }
}

nonisolated struct SettingsFileKeyID: Hashable, Sendable {
  let url: URL
}

nonisolated struct SettingsFileKey: SharedKey {
  let url: URL

  init(url: URL = SupacodePaths.settingsURL) {
    self.url = url
  }

  var id: SettingsFileKeyID {
    SettingsFileKeyID(url: url)
  }

  func load(context: LoadContext<SettingsFile>, continuation: LoadContinuation<SettingsFile>) {
    @Dependency(\.settingsFileStorage) var storage
    @Dependency(\.settingsUserDefaults) var userDefaults
    let decoder = Self.makeDecoder()
    if let data = try? storage.load(url),
      let settings = try? decoder.decode(SettingsFile.self, from: data)
    {
      SettingsFileMigration.cleanupLegacyKeys(in: userDefaults)
      continuation.resume(returning: settings)
      return
    }

    let initial = context.initialValue ?? .default
    if let migrated = SettingsFileMigration.migrate(from: userDefaults, initial: initial) {
      _ = try? save(migrated, storage: storage)
      continuation.resume(returning: migrated)
      return
    }

    _ = try? save(initial, storage: storage)
    continuation.resumeReturningInitialValue()
  }

  func subscribe(
    context _: LoadContext<SettingsFile>,
    subscriber _: SharedSubscriber<SettingsFile>
  ) -> SharedSubscription {
    SharedSubscription {}
  }

  func save(_ value: SettingsFile, context _: SaveContext, continuation: SaveContinuation) {
    @Dependency(\.settingsFileStorage) var storage
    do {
      try save(value, storage: storage)
      continuation.resume()
    } catch {
      continuation.resume(throwing: error)
    }
  }

  private func save(_ value: SettingsFile, storage: SettingsFileStorage) throws {
    let data = try Self.makeEncoder().encode(value)
    try storage.save(data, url)
  }

  private static func makeDecoder() -> JSONDecoder {
    JSONDecoder()
  }

  private static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }
}

nonisolated extension SharedReaderKey where Self == SettingsFileKey.Default {
  static var settingsFile: Self {
    Self[SettingsFileKey(), default: .default]
  }
}
