import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct ActionSheetRouteViewModifier: RouteReaderViewModifier {
  @MappedDispatch() private var dispatch

  var name: String
  var actionSheet: ActionSheet

  init(name: String, actionSheet: ActionSheet) {
    self.name = name
    self.actionSheet = actionSheet
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
      .actionSheet(isPresented: binding) { actionSheet }
      .nextWaypoint(with: isActive ? name : nil)
  }
}

extension View {

  /// Create a route that displays an action sheet.
  ///
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: The action sheet to display.
  /// - Returns: A view.
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  @available(OSX, unavailable)
  public func actionSheetRoute(_ name: String, content: () -> ActionSheet) -> some View {
    self.modifier(ActionSheetRouteViewModifier(name: name, actionSheet: content()))
  }
}
