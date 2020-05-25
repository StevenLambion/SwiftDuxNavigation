import Dispatch
import SwiftDux
import SwiftUI

/// Button that navigates to  a route.
public struct RouteLink<Label>: View where Label: View {
  @Environment(\.waypoint) private var waypoint
  @MappedDispatch() private var dispatch

  private var path: String
  private var scene: String?
  private var isDetail: Bool?
  private var skipIfAncestor: Bool
  private var animate: Bool
  private var label: Label

  /// Initiate a new `RouteLink`.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to. It may be a relative or absolute path.
  ///   - scene: The scene of the path.
  ///   - isDetail: If it's for the detail route.
  ///   - skipIfAncestor: Prevents the route from changing if the next path is an ancestor.
  ///   - animate: Animate the navigation.
  ///   - label: The label of the button.
  public init<T>(path: T, scene: String? = nil, isDetail: Bool? = nil, skipIfAncestor: Bool = true, animate: Bool = true, @ViewBuilder label: () -> Label)
  where T: LosslessStringConvertible {
    self.path = String(path)
    self.scene = scene
    self.isDetail = isDetail
    self.skipIfAncestor = skipIfAncestor
    self.animate = animate
    self.label = label()
  }

  public var body: some View {
    Button(action: navigate) { label }
  }

  private func navigate() {
    dispatch(waypoint.navigate(to: path, inScene: scene, isDetail: isDetail, skipIfAncestor: skipIfAncestor, animate: animate))
  }
}
