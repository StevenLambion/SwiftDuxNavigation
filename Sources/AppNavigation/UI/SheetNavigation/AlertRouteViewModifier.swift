import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct AlertRouteViewModifier: WaypointResolverViewModifier {
  @MappedDispatch() private var dispatch

  var name: String?
  var alert: Alert

  func body(content: Content, info: ResolvedWaypointInfo) -> some View {
    content
      .waypoint(with: info.animate ? info.nextWaypoint : nil)
      .alert(
        isPresented: Binding(
          get: { info.active },
          set: {
            guard !$0 else { return }
            self.dispatch(info.waypoint.navigate(to: ".."))
          }
        ),
        content: { alert }
      )
  }
}

extension View {

  /// Create a waypoint that displays an alert.
  ///
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: The alert to display.
  /// - Returns: A view.
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  @available(OSX, unavailable)
  public func alert(_ name: String, content: () -> Alert) -> some View {
    self.modifier(AlertRouteViewModifier(name: name, alert: content()))
  }
}
