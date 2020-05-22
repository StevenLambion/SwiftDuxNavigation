#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackRouteViewModifier<T, RouteContent>: ViewModifier
  where T: LosslessStringConvertible & Equatable, RouteContent: View {
    @Environment(\.store) private var anyStore
    @Environment(\.waypoint) private var waypoint

    var routeContent: (T) -> RouteContent

    @State private var childRoutes: StackRouteStorage = StackRouteStorage()
    @State private var stackNavigationOptions: StackNavigationOptions = StackNavigationOptions()

    func body(content: Content) -> some View {
      RouteReader { self.routeContents(content: content, routeInfo: $0) }
    }

    private func routeContents(content: Content, routeInfo: RouteInfo) -> some View {
      let pathParameter = routeInfo.pathParameter.flatMap { !$0.isEmpty ? T($0) : nil }
      let nextWaypoint = pathParameter != nil ? waypoint.next(with: pathParameter!) : nil
      return Group {
        if nextWaypoint != nil {
          content
            .id(nextWaypoint!.path)
            .nextWaypoint(with: nextWaypoint!)
            .environment(\.waypoint, nextWaypoint!)
            .stackRoutePreference(createRoute(pathParameter: pathParameter!))
            .stackNavigationPreference { $0 = self.stackNavigationOptions }
        } else {
          content
        }
      }
    }

    private func createRoute(pathParameter: T) -> StackRouteStorage {
      var routes = childRoutes
      let nextRouteInfo = waypoint.next(with: pathParameter)
      let newRoute = StackRoute(
        path: nextRouteInfo.path,
        fromBranch: waypoint.isBranch,
        view: routeContent(pathParameter)
          .nextWaypoint(with: nextRouteInfo)
          .onPreferenceChange(StackRoutePreferenceKey.self) {
            self.childRoutes = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
          .provideStore(anyStore)
      )
      if waypoint.isDetail {
        routes.detail.insert(newRoute, at: 0)
      } else {
        routes.master.insert(newRoute, at: 0)
      }
      return routes
    }
  }

  extension View {

    /// Add a new stack route that accepts a path parameter.
    /// - Parameter content: The view of the route.
    /// - Returns: A view.
    public func stackRoute<T, Content>(@ViewBuilder content: @escaping (T) -> Content) -> some View
    where T: LosslessStringConvertible & Equatable, Content: View {
      self.modifier(DynamicStackRouteViewModifier(routeContent: content))
    }
  }

#endif
