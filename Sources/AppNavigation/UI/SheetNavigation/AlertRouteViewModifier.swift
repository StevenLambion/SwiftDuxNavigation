import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct AlertRouteViewModifier: RouteReaderViewModifier {
  @MappedDispatch() private var dispatch

  var name: String
  var alert: Alert

  init(name: String, alert: Alert) {
    self.name = name
    self.alert = alert
  }

  public func body(content: Content, routeInfo: RouteInfo) -> some View {
    let isActive = routeInfo.pathParameter == name
    let binding = Binding(
      get: { isActive },
      set: {
        if !$0 {
          self.dispatch(routeInfo.waypoint.navigate(to: routeInfo.waypoint.path))
        }
      }
    )
    return
      content
      .nextWaypoint(with: isActive ? name : nil)
      .alert(isPresented: binding) { alert }
  }
}

extension View {

  /// Create a route that displays an alert.
  ///
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: The alert to display.
  /// - Returns: A view.
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  @available(OSX, unavailable)
  public func alertRoute(_ name: String, content: () -> Alert) -> some View {
    self.modifier(AlertRouteViewModifier(name: name, alert: content()))
  }
}
