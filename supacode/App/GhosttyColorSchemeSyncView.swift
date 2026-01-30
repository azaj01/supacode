import SwiftUI

struct GhosttyColorSchemeSyncView<Content: View>: View {
  @Environment(\.colorScheme) private var colorScheme
  let ghostty: GhosttyRuntime
  let onChange: (ColorScheme) -> Void
  let content: Content

  init(
    ghostty: GhosttyRuntime,
    onChange: @escaping (ColorScheme) -> Void = { _ in },
    @ViewBuilder content: () -> Content
  ) {
    self.ghostty = ghostty
    self.onChange = onChange
    self.content = content()
  }

  var body: some View {
    content
      .task {
        apply(colorScheme)
      }
      .onChange(of: colorScheme) { _, newValue in
        apply(newValue)
      }
  }

  private func apply(_ scheme: ColorScheme) {
    ghostty.setColorScheme(scheme)
    onChange(scheme)
  }
}
