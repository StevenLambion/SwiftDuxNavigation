import SwiftDux
import SwiftUI

internal struct SheetRouteViewModifier<Modal>: WaypointResolverViewModifier where Modal: View {
  @MappedDispatch() private var dispatch

  var name: String?
  var modal: () -> Modal

  init(name: String, @ViewBuilder modal: @escaping () -> Modal) {
    self.name = name
    self.modal = modal
  }

  public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
    content
      .waypoint(with: info.animate ? info.nextWaypoint : nil)
      .sheet(
        isPresented: Binding(
          get: { info.active },
          set: {
            guard !$0 else { return }
            self.dispatch(info.waypoint.navigate(to: ".."))
          }
        ),
        content: {
          self.modal().waypoint(with: info.nextWaypoint)
        }
      )
  }
}

extension View {

  /// Create  a waypoint that displays a modal sheet.
  /// 
  /// - Parameters:
  ///   - name: The name of the route
  ///   - content: A view to display as a sheet.
  /// - Returns: A view.
  public func sheet<Modal>(_ name: String, @ViewBuilder content: @escaping () -> Modal) -> some View where Modal: View {
    self.modifier(SheetRouteViewModifier(name: name, modal: content))
  }
}
