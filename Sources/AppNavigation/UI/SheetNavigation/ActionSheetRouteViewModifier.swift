import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct ActionSheetRouteViewModifier: ViewModifier {
  @MappedDispatch() private var dispatch

  var name: String
  var actionSheet: () -> ActionSheet

  init(name: String, actionSheet: @escaping () -> ActionSheet) {
    self.name = name
    self.actionSheet = actionSheet
  }

  public func body(content: Content) -> some View {
    RouteContents {
      self.routeContents(content: content, routeInfo: $0, leg: $1, route: $2)
    }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    let isActive = leg?.component == name
    let binding = Binding(
      get: { isActive },
      set: {
        if !$0 {
          self.dispatch(NavigationAction.navigate(to: routeInfo.path, in: routeInfo.sceneName, animate: true))
        }
      }
    )
    return
      content
      .actionSheet(isPresented: binding, content: self.actionSheet)
      .environment(\.routeInfo, isActive ? routeInfo.next(with: name) : routeInfo)
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
  public func actionSheetRoute(_ name: String, @ViewBuilder content: @escaping () -> ActionSheet) -> some View {
    self.modifier(ActionSheetRouteViewModifier(name: name, actionSheet: content))
  }
}
