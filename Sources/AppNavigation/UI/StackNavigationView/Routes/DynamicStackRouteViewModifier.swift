#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackRouteViewModifier<T, RouteContent>: ViewModifier
  where T: LosslessStringConvertible & Equatable, RouteContent: View {
    @Environment(\.store) private var anyStore
    @Environment(\.currentRoute) private var currentRoute

    var routeContent: (T) -> RouteContent

    @State private var childRoutes: StackRouteStorage = StackRouteStorage()
    @State private var stackNavigationOptions: Set<StackNavigationOption> = Set()

    func body(content: Content) -> some View {
      RouteContents { self.routeContents(content: content, routeInfo: $0) }
    }

    private func routeContents(content: Content, routeInfo: RouteInfo) -> some View {
      let pathParameter = routeInfo.pathParameter.flatMap { !$0.isEmpty ? T($0) : nil }
      let nextRoute = pathParameter != nil ? currentRoute.next(with: pathParameter!) : nil
      return Group {
        if nextRoute != nil {
          content
            .id(nextRoute!.path)
            .environment(\.currentRoute, nextRoute!)
            .stackRoutePreference(createRoute(pathParameter: pathParameter!))
            .stackNavigationPreference(stackNavigationOptions)
        } else {
          content
        }
      }
    }

    private func createRoute(pathParameter: T) -> StackRouteStorage {
      var routes = childRoutes
      let nextRouteInfo = currentRoute.next(with: pathParameter)
      let newRoute = StackRoute(
        path: nextRouteInfo.path,
        fromBranch: currentRoute.isBranch,
        view: routeContent(pathParameter)
          .environment(\.currentRoute, nextRouteInfo)
          .onPreferenceChange(StackRoutePreferenceKey.self) {
            self.childRoutes = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
          .provideStore(anyStore)
      )
      if currentRoute.isDetail {
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
