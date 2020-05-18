import SwiftDux
import SwiftUI

internal struct DynamicDetailView<Content, T>: View where Content: View, T: LosslessStringConvertible & Equatable {
  private var content: (T) -> Content

  init(@ViewBuilder content: @escaping (T) -> Content) {
    self.content = content
  }

  var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
    let pathParam = leg.flatMap { !$0.component.isEmpty ? T($0.component) : nil }
    return Group {
      if pathParam != nil {
        content(pathParam!)
          .id(leg!.component)
          .environment(\.currentRoute, currentRoute.next(with: pathParam!))
      }
    }
  }
}
