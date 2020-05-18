#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackRouteViewModifier<T, BranchView>: ViewModifier
  where T: LosslessStringConvertible & Equatable, BranchView: View {
    @Environment(\.currentRoute) private var currentRoute
    @MappedDispatch() private var dispatch

    var branchView: (T) -> BranchView

    @State private var childRoutes: StackRouteStorage = StackRouteStorage()
    @State private var stackNavigationOptions: Set<StackNavigationOption> = Set()

    func body(content: Content) -> some View {
      RouteContents { currentRoute, leg, route in
        self.routeContents(content: content, currentRoute: currentRoute, leg: leg, route: route)
      }
    }

    private func routeContents(content: Content, currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
      let pathParam = leg.flatMap { !$0.component.isEmpty ? T($0.component) : nil }
      return Group {
        if pathParam != nil {
          content
            .id(leg!.component)
            .environment(\.currentRoute, currentRoute.next(with: pathParam!))
            .stackRoutePreference(createRoute(pathParam: pathParam!))
            .stackNavigationPreference(stackNavigationOptions)
        } else {
          content
        }
      }
    }

    private func createRoute(pathParam: T) -> StackRouteStorage {
      var routes = childRoutes
      let nextRouteInfo = currentRoute.next(with: pathParam)
      let newRoute = StackRoute(
        path: nextRouteInfo.path,
        fromBranch: currentRoute.isBranch,
        view: branchView(pathParam)
          .environment(\.currentRoute, nextRouteInfo)
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

    /// Add a new stack route that accepts a path parameter.
    /// - Parameter branchView: The view of the route.
    /// - Returns: A view.
    public func stackRoute<T, V>(@ViewBuilder branchView: @escaping (T) -> V) -> some View
    where T: LosslessStringConvertible & Equatable, V: View {
      self.modifier(DynamicStackRouteViewModifier(branchView: branchView))
    }
  }

#endif
