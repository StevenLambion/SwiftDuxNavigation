import SwiftDux
import SwiftUI

/// A waypoint that provides a selection binding.
///
/// This waypoint can be used to provide navigatoinal functionality to other views such as Lists and TabViews.
public struct Selection<T, Content>: View where T: LosslessStringConvertible, Content: View {
  @Environment(\.actionDispatcher) private var dispatch

  public var initialValue: T?
  public var isDetail: Bool? = nil
  private var content: (ActionDispatcher, Waypoint) -> Content?

  /// Initiate a SelectionWaypoint with an optional selection.
  ///
  /// - Parameters:
  ///   - initialValue: An initial optional value.
  ///   - isDetail: If the selection should represent the root of the detail route.
  ///   - content: A closure that returns the content of the waypoint.
  public init(initialValue: T?, isDetail: Bool? = nil, @ViewBuilder content: @escaping (Binding<T?>) -> Content) {
    self.initialValue = initialValue
    self.isDetail = isDetail
    self.content = { _, waypoint -> Content? in content(waypoint.destination(as: T.self)) }
  }

  /// Initiate a SelectionWaypoint with an optional selection.
  ///
  /// - Parameters:
  ///   - type: The type of selection value.
  ///   - isDetail: If the selection should represent the root of the detail route.
  ///   - content: A closure that returns the content of the waypoint.
  public init(ofType type: T.Type, isDetail: Bool? = nil, @ViewBuilder content: @escaping (Binding<T?>) -> Content) {
    self.initialValue = nil
    self.isDetail = isDetail
    self.content = { _, waypoint -> Content? in content(waypoint.destination(as: T.self)) }
  }

  /// Initiate a SelectionWaypoint with an initial selection.
  ///
  /// - Parameters:
  ///   - initialValue: The initial selection value.
  ///   - isDetail: If the selection should represent the root of the detail route.
  ///   - content: A closure that returns the content of the waypoint.
  public init(initialValue: T, isDetail: Bool? = nil, @ViewBuilder content: @escaping (Binding<T>) -> Content) {
    self.initialValue = initialValue
    self.isDetail = isDetail
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

  public var body: some View {
    WaypointView(.parameter(defaultValue: initialValue), isDetail: isDetail) { waypoint in
      content(dispatch, waypoint)?.environment(\.waypoint, waypoint)
    }
  }
}
