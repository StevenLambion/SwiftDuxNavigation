import SwiftDux
import SwiftUI

public struct DynamicStackRouteViewModifier<T, BranchView>: ViewModifier
where T: LosslessStringConvertible & Equatable, BranchView: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  var branchView: (T) -> BranchView

  @State private var childRoutes: [StackRoute] = []
  @State private var stackNavigationOptions: Set<StackNavigationOption> = Set()

  public func body(content: Content) -> some View {
    RouteContents { routeInfo, leg, route in
      self.routeContents(content: content, routeInfo: routeInfo, leg: leg, route: route)
    }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    let pathParam = leg.flatMap { !$0.component.isEmpty ? T($0.component) : nil }
    return Group {
      if pathParam != nil {
        content
          .stackRoutePreference([createRoute(pathParam: pathParam!)] + childRoutes)
          .navigationPreference(stackNavigationOptions)
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
        .onPreferenceChange(StackNavigationPreferenceKey.self) {
          self.stackNavigationOptions = $0
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
    self.modifier(DynamicStackRouteViewModifier(branchView: branchView))
  }
}
