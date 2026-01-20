//
//  ContentView.swift
//  supacode
//
//  Created by khoi on 20/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var filter = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(filter: $filter)
        } detail: {
            EmptyStateView()
                .navigationTitle("Supacode")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: {}) {
                            Image(systemName: "sidebar.left")
                        }
                        Button(action: {}) {
                            Image(systemName: "square.and.pencil")
                        }
                        Button(action: {}) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct SidebarView: View {
    @Binding var filter: String

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Projects") {
                    ProjectRow(name: "suparepo", detail: "main")
                }
            }
            .listStyle(.sidebar)
            Divider()
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                TextField("Filter", text: $filter)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(8)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 220)
    }
}

private struct ProjectRow: View {
    let name: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
            Text("Open a project or worktree")
                .font(.headline)
            Text("Double-click an item in the sidebar, or press Cmd+O.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open...") {}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .multilineTextAlignment(.center)
    }
}
