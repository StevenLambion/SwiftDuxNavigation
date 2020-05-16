import SwiftDux
import SwiftUI

internal struct StackRouteViewModifier<BranchView>: ViewModifier where BranchView: View {
  @MappedDispatch() private var dispatch

  var branchView: BranchView

  @State private var childRoutes: [StackRoute] = []
  @State private var stackNavigationOptions: Set<StackNavigationOption> = Set()

  func body(content: Content) -> some View {
    RouteContents { routeInfo, leg, route in
      self.routeContents(content: content, routeInfo: routeInfo, leg: leg, route: route)
    }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    Group {
      if leg != nil {
        content
          .onPreferenceChange(StackRoutePreferenceKey.self) {
            self.childRoutes = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
          .stackRoutePreference([createRoute(from: routeInfo)] + childRoutes)
          .navigationPreference(stackNavigationOptions)
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
    self.modifier(StackRouteViewModifier(branchView: branchView()))
  }
}
