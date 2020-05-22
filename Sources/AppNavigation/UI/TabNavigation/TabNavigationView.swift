import SwiftDux
import SwiftUI

/// A tab view that navigates using  routes.
public struct TabNavigationView<Content, T>: RouteReaderView where Content: View, T: LosslessStringConvertible & Hashable {
  @MappedDispatch() private var dispatch

  private var content: Content
  private var initialTab: T

  /// Initiate a new `TabNavigationView`.
  ///
  /// - Parameters:
  ///   - initialTab: The initial selected tab.
  ///   - content: The contents of the tabView. Use the same API as a SwiftUI `TabView` to set up the tab items.
  public init(initialTab: T, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.initialTab = initialTab
  }

  public func body(routeInfo: RouteInfo) -> some View {
    let pathParameter = createPathParameterBinding(waypoint: routeInfo.waypoint, pathParameter: routeInfo.pathParameter)
    return TabView(selection: pathParameter) { content }
      .nextWaypoint(with: String(pathParameter.wrappedValue))
      .onAppear {
        if routeInfo.path == routeInfo.waypoint.path {
          self.dispatch(routeInfo.waypoint.navigate(to: String(pathParameter.wrappedValue), animate: false))
        }
        self.dispatch(routeInfo.waypoint.beginCaching())
      }
  }

  private func createPathParameterBinding(waypoint: Waypoint, pathParameter: String?) -> Binding<T> {
    let pathParameter = pathParameter.flatMap { T($0) } ?? initialTab
    return Binding(
      get: { pathParameter },
      set: {
        let nextPathParam = String($0)
        self.dispatch(waypoint.navigate(to: String(nextPathParam)))
        self.dispatch(waypoint.completeNavigation())
      }
    )
  }
}
