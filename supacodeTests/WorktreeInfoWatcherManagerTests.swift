import Foundation
import Testing

@testable import supacode

@MainActor
struct WorktreeInfoWatcherManagerTests {
  @Test func defersLineChangesUntilSchedule() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
    let worktreeDirectory = tempRoot.appending(path: "wt")
    let gitDirectory = worktreeDirectory.appending(path: ".git")
    try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
    let headURL = gitDirectory.appending(path: "HEAD")
    try "ref: refs/heads/main\n".write(to: headURL, atomically: true, encoding: .utf8)

    let manager = WorktreeInfoWatcherManager(
      focusedInterval: .milliseconds(50),
      unfocusedInterval: .milliseconds(50)
    )
    let worktree = Worktree(
      id: worktreeDirectory.path(percentEncoded: false),
      name: "eagle",
      detail: "detail",
      workingDirectory: worktreeDirectory,
      repositoryRootURL: tempRoot
    )
    let stream = manager.eventStream()
    let collector = EventCollector()
    let task = Task {
      for await event in stream {
        if Task.isCancelled {
          break
        }
        await collector.append(event)
      }
    }

    manager.handleCommand(.setPullRequestTrackingEnabled(false))
    manager.handleCommand(.setWorktrees([worktree]))
    manager.handleCommand(.setSelectedWorktreeID(worktree.id))

    try? await Task.sleep(for: .milliseconds(20))
    let earlyEvents = await collector.snapshot()
    let earlyHasFilesChanged = earlyEvents.contains { event in
      if case .filesChanged(let id) = event {
        return id == worktree.id
      }
      return false
    }
    #expect(earlyHasFilesChanged == false)

    try? await Task.sleep(for: .milliseconds(80))
    let laterEvents = await collector.snapshot()
    let laterHasFilesChanged = laterEvents.contains { event in
      if case .filesChanged(let id) = event {
        return id == worktree.id
      }
      return false
    }
    #expect(laterHasFilesChanged == true)

    manager.handleCommand(.stop)
    await task.value
    try fileManager.removeItem(at: tempRoot)
  }
}

actor EventCollector {
  private var events: [WorktreeInfoWatcherClient.Event] = []

  func append(_ event: WorktreeInfoWatcherClient.Event) {
    events.append(event)
  }

  func snapshot() -> [WorktreeInfoWatcherClient.Event] {
    events
  }
}
