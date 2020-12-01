import SwiftDux
import SwiftUI

internal struct StackItemWaypoint<Destination>: ViewModifier where Destination: View {
  @Environment(\.store) private var store

  var type: WaypointType
  var isDetail: Bool?
  var destination: Destination

  func body(content: Content) -> some View {
    WaypointView(type, isDetail: isDetail) { waypoint in
      VStack {
        content
        NavigationLink(
          destination: destination.environment(\.waypoint, waypoint).provideStore(store),
          isActive: waypoint.$isActive
        ) { EmptyView() }.isDetailLink(waypoint.isDetail)
      }
    }
  }
}

extension View {

  /// Add a new stacking waypoint for the NavigationView.
  ///
  /// - Parameters:
  ///   - type: The type of waypoint.
  ///   - isDetail: Indicate that it's the root detail route.
  ///   - content: The view of the waypoint.
  /// - Returns: A view.
  public func stackItem<Destination>(_ type: WaypointType, isDetail: Bool? = nil, @ViewBuilder content: () -> Destination) -> some View
  where Destination: View {
    self.modifier(StackItemWaypoint(type: type, isDetail: isDetail, destination: content()))
  }
}
