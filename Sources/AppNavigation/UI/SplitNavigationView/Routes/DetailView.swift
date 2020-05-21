import SwiftDux
import SwiftUI

internal struct DetailView<Content>: View where Content: View {
  private var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    RouteReader { _ in
      self.content
    }
  }
}
