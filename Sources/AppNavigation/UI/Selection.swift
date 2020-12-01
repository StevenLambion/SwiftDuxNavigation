import SwiftDux
import SwiftUI

/// A waypoint that provides a selection binding.
///
/// This waypoint can be used to provide navigatoinal functionality to other views such as Lists and TabViews.
public struct Selection<T, Content>: View where T: LosslessStringConvertible, Content: View {
  @Environment(\.actionDispatcher) private var dispatch

  public var initialValue: T?
  private var content: (ActionDispatcher, Waypoint) -> Content?

  /// Initiate a SelectionWaypoint with an initial selection.
  ///
  /// - Parameters:
  ///   - initialValue: The initial selection value.
  ///   - content: A closure that returns the content of the waypoint.
  public init(initialValue: T, @ViewBuilder content: @escaping (Binding<T>) -> Content) {
    self.initialValue = initialValue
    self.content = { dispatch, waypoint in
      let destination = waypoint.destination
      let view = T(destination ?? "").map { value in
        content(Binding(get: { value }, set: { waypoint.$destination.wrappedValue = $0.description }))
      }

      if view == nil {
        dispatch(waypoint.navigate(to: ".."))
      }

      return view
    }
  }

  /// Initiate a SelectionWaypoint with an optional selection.
  ///
  /// - Parameters:
  ///   - type: The type of selection value.
  ///   - content: A closure that returns the content of the waypoint.
  public init(ofType type: T.Type, @ViewBuilder content: @escaping (Binding<T?>) -> Content) {
    self.initialValue = nil
    self.content = { _, waypoint -> Content? in content(waypoint.destination(as: T.self)) }
  }

  public var body: some View {
    WaypointView(.parameter(defaultValue: initialValue)) { waypoint in
      content(dispatch, waypoint)
    }
  }
}
