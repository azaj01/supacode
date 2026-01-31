import SwiftUI

struct AppLoadingView: View {
  var body: some View {
    VStack {
      Text("Supacode")
        .font(.title2)
        .bold()
      ProgressView()
        .controlSize(.large)
    }
  }
}
