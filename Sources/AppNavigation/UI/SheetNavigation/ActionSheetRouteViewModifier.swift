import SwiftDux
import SwiftUI

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(OSX, unavailable)
internal struct ActionSheetRouteViewModifier: ViewModifier {
  @Environment(\.store) var anyStore
  @MappedDispatch() private var dispatch

  var name: String
  var actionSheet: ActionSheet

  init(name: String, actionSheet: ActionSheet) {
    self.name = name
    self.actionSheet = actionSheet
  }

  public func body(content: Content) -> some View {
    RouteContents { self.routeContents(content: content, routeInfo: $0) }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo) -> some View {
    let isActive = routeInfo.pathParameter == name
    let binding = Binding(
      get: { isActive },
      set: {
        if !$0 {
          self.dispatch(routeInfo.current.navigate(to: routeInfo.current.path))
        }
      }
    )
    return
      content
      .actionSheet(isPresented: binding) { actionSheet }
      .environment(\.currentRoute, isActive ? routeInfo.current.next(with: name) : routeInfo.current)
      .provideStore(anyStore)
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
