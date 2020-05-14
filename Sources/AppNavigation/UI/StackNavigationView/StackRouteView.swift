import SwiftDux
import SwiftUI

public struct StackRouteView<Content, BranchView>: View where Content: View, BranchView: View {
  @MappedDispatch() private var dispatch

  var content: Content
  var branchView: BranchView

  public var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    Group {
      if leg != nil {
        content.stackRoutePreference([createRoute(from: routeInfo)])
      } else {
        content
      }
    }
  }

  private func createRoute(from routeInfo: RouteInfo) -> StackRoute {
    StackRoute(
      path: routeInfo.path,
      fromBranch: routeInfo.isBranch,
      view: branchView
    )
  }
}

extension View {

  /// Add a new stack route.
  /// - Parameter branchView: The view of the route.
  /// - Returns: A view.
  public func stackRoute<V>(@ViewBuilder branchView: () -> V) -> some View where V: View {
    StackRouteView(content: self, branchView: branchView())
  }
}
