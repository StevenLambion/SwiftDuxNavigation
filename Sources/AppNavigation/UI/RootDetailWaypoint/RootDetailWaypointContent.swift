import SwiftDux
import SwiftUI

/// The root waypoint of the detail route. Use `View.detailItem` to set the waypoint.
///
/// Navigation views may access the environment value to handle the detail route.
public struct RootDetailWaypointContent {
  public var waypoint: Waypoint
  public var view: AnyView

  init<Content>(waypoint: Waypoint, content: Content) where Content: View {
    self.waypoint = waypoint
    self.view = AnyView(content)
  }
}

internal final class RootDetailWaypointContentKey: EnvironmentKey {
  public static var defaultValue: RootDetailWaypointContent? = nil
}

extension EnvironmentValues {

  /// The current root detail waypoint's content.
  public var rootDetailWaypointContent: RootDetailWaypointContent? {
    get { self[RootDetailWaypointContentKey] }
    set { self[RootDetailWaypointContentKey] = newValue }
  }
}

extension View {

  /// Clears the current detail item for the child view hierarchy.
  ///
  /// This is useful for navigation views that may implement the detail routes, and want to
  /// make sure child navigational views don't utilize it.
  /// - Returns: The view.
  public func clearDetailItem() -> some View {
    self.transformEnvironment(\.rootDetailWaypointContent) { $0 = nil }
  }
}
