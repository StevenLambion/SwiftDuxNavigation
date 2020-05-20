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
    return content.sheet(isPresented: binding) {
      self.modal().environment((\.currentRoute), routeInfo.current.next(with: self.name))
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
