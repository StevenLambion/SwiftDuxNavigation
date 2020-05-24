import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct ActionSheetRouteViewModifier: WaypointResolverViewModifier {
  @MappedDispatch() private var dispatch

  var name: String?
  var actionSheet: ActionSheet

  public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
    content
      .waypoint(with: info.animate ? info.nextWaypoint : nil)
      .actionSheet(
        isPresented: Binding(
          get: { info.active },
          set: {
            guard !$0 else { return }
            self.dispatch(info.waypoint.navigate(to: ".."))
          }
        ),
        content: { actionSheet }
      )
  }
}

extension View {

  /// Create a waypoint that displays an action sheet.
  ///
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: The action sheet to display.
  /// - Returns: A view.
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  @available(OSX, unavailable)
  public func actionSheet(_ name: String, content: () -> ActionSheet) -> some View {
    self.modifier(ActionSheetRouteViewModifier(name: name, actionSheet: content()))
  }
}
