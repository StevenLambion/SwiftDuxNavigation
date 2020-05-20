#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackRouteViewModifier<RouteContent>: ViewModifier where RouteContent: View {
    var routeContent: RouteContent

    @State private var childRoutes: StackRouteStorage = StackRouteStorage()
    @State private var stackNavigationOptions: Set<StackNavigationOption> = Set()

    func body(content: Content) -> some View {
      RouteContents { currentRoute, leg, route in
        self.routeContents(content: content, currentRoute: currentRoute, leg: leg, route: route)
      }
    }

    private func routeContents(content: Content, currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
      Group {
        if leg != nil || currentRoute.path == route.path {
          content
            .onPreferenceChange(StackRoutePreferenceKey.self) {
              self.childRoutes = $0
            }
            .onPreferenceChange(StackNavigationPreferenceKey.self) {
              self.stackNavigationOptions = $0
            }
            .stackRoutePreference(createRoute(from: currentRoute))
            .stackNavigationPreference(stackNavigationOptions)
        } else {
          content
        }
      }
    }

    private func createRoute(from currentRoute: CurrentRoute) -> StackRouteStorage {
      var routes = childRoutes
      let newRoute = StackRoute(
        path: currentRoute.path,
        fromBranch: currentRoute.isBranch,
        view:
          routeContent
          .onPreferenceChange(StackRoutePreferenceKey.self) {
            self.childRoutes = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
      )
      if currentRoute.isDetail {
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
