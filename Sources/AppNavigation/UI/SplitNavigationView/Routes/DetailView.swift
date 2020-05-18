import SwiftDux
import SwiftUI

internal struct DetailView<Content>: View where Content: View {
  private var content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
    content()
  }
}
