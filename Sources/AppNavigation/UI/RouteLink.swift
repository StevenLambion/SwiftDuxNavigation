import Dispatch
import SwiftDux
import SwiftUI

/// A navigable button.
public struct RouteLink<Label>: View where Label: View {
  @Environment(\.waypoint) private var waypoint
  @Environment(\.actionDispatcher) private var dispatch

  public var path: String
  public var routeName: String?
  public var isDetail: Bool?
  public var skipIfAncestor: Bool
  public var label: Label

  /// Initiate a RouteLink.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to. It may be a relative or absolute path.
  ///   - routeName: The name of the route.
  ///   - isDetail: Whether to navigate the detail route.
  ///   - skipIfAncestor: Prevents navigation if the path is an ancestor.
  ///   - label: The label of the button.
  public init<T>(path: T, routeName: String? = nil, isDetail: Bool? = nil, skipIfAncestor: Bool = true, @ViewBuilder label: () -> Label)
  where T: LosslessStringConvertible {
    self.path = String(path)
    self.routeName = routeName
    self.isDetail = isDetail
    self.skipIfAncestor = skipIfAncestor
    self.label = label()
  }

  public var body: some View {
    Button(action: navigate) { label }
  }

  private func navigate() {
    dispatch(waypoint.navigate(to: path, inRoute: routeName, isDetail: isDetail, skipIfAncestor: skipIfAncestor))
  }
}
