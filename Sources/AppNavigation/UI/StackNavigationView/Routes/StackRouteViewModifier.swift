#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackRouteViewModifier<RouteContent>: RouteReaderViewModifier where RouteContent: View {
    @Environment(\.store) private var anyStore
    var routeContent: RouteContent

    @State private var childRoutes: StackRouteStorage = StackRouteStorage()
    @State private var stackNavigationOptions: StackNavigationOptions = StackNavigationOptions()

    public func body(content: Content, routeInfo: RouteInfo) -> some View {
      Group {
        if routeInfo.pathParameter != nil || routeInfo.waypoint.path == routeInfo.path {
          content
            .onPreferenceChange(StackRoutePreferenceKey.self) {
              self.childRoutes = $0
            }
            .onPreferenceChange(StackNavigationPreferenceKey.self) {
              self.stackNavigationOptions = $0
            }
            .stackRoutePreference(createRoute(from: routeInfo.waypoint))
            .stackNavigationPreference { $0 = self.stackNavigationOptions }
        } else {
          content
        }
      }
    }

    private func createRoute(from waypoint: Waypoint) -> StackRouteStorage {
      var routes = childRoutes
      let newRoute = StackRoute(
        path: waypoint.path,
        fromBranch: waypoint.isBranch,
        view:
          routeContent
          .onPreferenceChange(StackRoutePreferenceKey.self) {
            self.childRoutes = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
          .provideStore(anyStore)
      )
      if waypoint.isDetail {
        routes.detail.append(newRoute)
      } else {
        routes.master.append(newRoute)
      }
      return routes
    }
  }

  extension View {

    /// Add a new stack route.
    /// - Parameter content: The view of the route.
    /// - Returns: A view.
    public func stackRoute<Content>(@ViewBuilder content: () -> Content) -> some View where Content: View {
      self.modifier(StackRouteViewModifier(routeContent: content()))
    }
  }

#endif
