import SwiftDux
import SwiftUI

public struct DynamicStackRouteView<Content, T, BranchView>: View
where Content: View, T: LosslessStringConvertible & Equatable, BranchView: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  internal var content: Content
  internal var branchView: (T) -> BranchView

  @State private var childRoutes: [StackRoute] = []

  public var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    let pathParam = leg.flatMap { !$0.component.isEmpty ? T($0.component) : nil }
    return Group {
      if pathParam != nil {
        content.stackRoutePreference([createRoute(pathParam: pathParam!)] + childRoutes)
      } else {
        content
      }
    }
  }

  private func createRoute(pathParam: T) -> StackRoute {
    let nextRouteInfo = routeInfo.next(with: pathParam)
    return StackRoute(
      path: nextRouteInfo.path,
      fromBranch: routeInfo.isBranch,
      view: branchView(pathParam)
        .environment(\.routeInfo, nextRouteInfo)
        .onPreferenceChange(StackRoutePreferenceKey.self) {
          self.childRoutes = $0
        }
    )
  }
}

extension View {

  /// Add a new stack route that accepts a path parameter.
  /// - Parameter branchView: The view of the route.
  /// - Returns: A view.
  public func stackRoute<T, V>(@ViewBuilder branchView: @escaping (T) -> V) -> some View
  where T: LosslessStringConvertible & Equatable, V: View {
    DynamicStackRouteView(content: self, branchView: branchView)
  }
}
