//
//  supacodeApp.swift
//  supacode
//
//  Created by khoi on 20/1/26.
//

import GhosttyKit
import SwiftUI

private enum GhosttyCLI {
  static let argv: [UnsafeMutablePointer<CChar>?] = {
    var args: [UnsafeMutablePointer<CChar>?] = []
    let executable = CommandLine.arguments.first ?? "supacode"
    args.append(strdup(executable))
    for shortcut in AppShortcuts.all {
      args.append(strdup("--keybind=\(shortcut.ghosttyKeybind)=unbind"))
    }
    args.append(nil)
    return args
  }()
}

@main
@MainActor
struct SupacodeApp: App {
  @State private var ghostty: GhosttyRuntime
  @State private var settings = SettingsModel()
  @State private var repositoryStore: RepositoryStore?
  @State private var updateController: UpdateController

  @MainActor init() {
    if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("ghostty") {
      setenv("GHOSTTY_RESOURCES_DIR", resourceURL.path, 1)
    }
    GhosttyCLI.argv.withUnsafeBufferPointer { buffer in
      let argc = UInt(max(0, buffer.count - 1))
      let argv = UnsafeMutablePointer(mutating: buffer.baseAddress)
      if ghostty_init(argc, argv) != GHOSTTY_SUCCESS {
        preconditionFailure("ghostty_init failed")
      }
    }
    _ghostty = State(initialValue: GhosttyRuntime())
    let settingsModel = SettingsModel()
    _settings = State(initialValue: settingsModel)
    _updateController = State(initialValue: UpdateController(settings: settingsModel))
  }

  @MainActor
  private func ensureRepositoryStore() {
    if repositoryStore == nil {
      repositoryStore = makeRepositoryStore()
    }
  }

  var body: some Scene {
    WindowGroup {
      if let repositoryStore {
        ContentView(runtime: ghostty)
          .environment(settings)
          .environment(updateController)
          .environment(repositoryStore)
          .preferredColorScheme(settings.preferredColorScheme)
      } else {
        ProgressView()
          .task {
            ensureRepositoryStore()
          }
      }
    }
    .commands {
      if let repositoryStore {
        OpenRepositoryCommands(repositoryStore: repositoryStore)
        WorktreeCommands(repositoryStore: repositoryStore)
      }
      SidebarCommands()
      TerminalCommands()
      UpdateCommands(updateController: updateController)
    }
    Settings {
      if let repositoryStore {
        SettingsView()
          .environment(settings)
          .environment(updateController)
          .environment(repositoryStore)
      } else {
        ProgressView()
          .task {
            ensureRepositoryStore()
          }
      }
    }
  }
}
