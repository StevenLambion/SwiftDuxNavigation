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

  private func routeContents(routeInfo: RouteInfo) -> some View {
    let pathParameter = routeInfo.pathParameter.flatMap { !$0.isEmpty ? T($0) : nil }
    return Group {
      if pathParameter != nil {
        content(pathParameter!)
          .id("detail@" + (routeInfo.path ?? routeInfo.current.path))
          .environment(\.currentRoute, routeInfo.current.next(with: pathParameter!))
      }
    }
  }
}
