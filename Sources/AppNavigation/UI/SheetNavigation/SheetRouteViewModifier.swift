import SwiftDux
import SwiftUI

internal struct SheetRouteViewModifier<Modal>: ViewModifier where Modal: View {
  @MappedDispatch() private var dispatch

  var name: String
  var modal: () -> Modal

  init(name: String, @ViewBuilder modal: @escaping () -> Modal) {
    self.name = name
    self.modal = modal
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
    return content.sheet(isPresented: binding) {
      self.modal().environment((\.routeInfo), routeInfo.next(with: self.name))
    }
  }
}

extension View {

  /// Create  a route that displays a modal sheet.
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: A view to display as a sheet.
  /// - Returns: A view.
  public func sheetRoute<Modal>(_ name: String, @ViewBuilder content: @escaping () -> Modal) -> some View where Modal: View {
    self.modifier(SheetRouteViewModifier(name: name, modal: content))
  }
}