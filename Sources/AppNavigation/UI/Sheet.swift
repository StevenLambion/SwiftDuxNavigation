import SwiftDux
import SwiftUI

internal struct SheetWaypoint<Modal>: ViewModifier where Modal: View {
  @Environment(\.store) private var store
  @Environment(\.actionDispatcher) private var dispatch

  var type: WaypointType
  var modal: Modal

  public func body(content: Content) -> some View {
    WaypointView(type) { waypoint in
      content
        .sheet(
          isPresented: waypoint.$isActive,
          content: { self.modal.environment(\.waypoint, waypoint).provideStore(store) }
        )
    }
  }
}

extension View {

  /// Create  a waypoint that displays a modal sheet.
  ///
  /// - Parameters:
  ///   - type: The type of waypoint.
  ///   - content: A view to display as a sheet.
  /// - Returns: A view.
  public func sheet<Modal>(_ type: WaypointType, @ViewBuilder content: () -> Modal) -> some View where Modal: View {
    self.modifier(SheetWaypoint(type: type, modal: content()))
  }
}
