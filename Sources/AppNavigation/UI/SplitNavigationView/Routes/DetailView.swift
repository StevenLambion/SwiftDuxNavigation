import SwiftDux
import SwiftUI

internal struct DetailView<Content>: View where Content: View {
  private var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(routeInfo: RouteInfo) -> some View {
    content.id("detail@" + routeInfo.current.path)
  }
}
