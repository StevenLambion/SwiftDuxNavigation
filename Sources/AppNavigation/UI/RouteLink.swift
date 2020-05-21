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
  private var animate: Bool
  private var label: Label

  /// Initiate a new `RouteLink`.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to. It may be a relative or absolute path.
  ///   - scene: The scene of the path.
  ///   - isDetail: If it's for the detail route.
  ///   - animate: Animate the navigation.
  ///   - label: The label of the button.
  public init<T>(path: T, scene: String? = nil, isDetail: Bool? = nil, animate: Bool = true, @ViewBuilder label: () -> Label)
  where T: LosslessStringConvertible {
    self.path = String(path)
    self.scene = scene
    self.isDetail = isDetail
    self.animate = animate
    self.label = label()
  }

  public var body: some View {
    Button(action: self.navigate) { label }
  }

  private func navigate() {
    dispatch(self.waypoint.navigate(to: self.path, inScene: self.scene, isDetail: self.isDetail != false, animate: self.animate))
  }
}
