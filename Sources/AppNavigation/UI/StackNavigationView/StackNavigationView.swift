import SwiftDux
import SwiftUI

/// Create a stack-style navigation.
public struct StackNavigationView<RootView>: WaypointResolverView where RootView: View {
  private var rootView: RootView

  /// Initiate a `StackNavigationView` with a root view.
  /// - Parameter rootView: The root view of the stack.
  public init(@ViewBuilder rootView: () -> RootView) {
    self.rootView = rootView()
  }

  public func body(info: ResolvedWaypointInfo) -> some View {
    NativeStackNavigationView(
      animate: info.animate,
      rootView: rootView.waypoint(with: info.nextWaypoint)
    )
    .opacity(!info.animate && !info.completed ? 0 : 1)
    .edgesIgnoringSafeArea(.all)
    .waypoint(with: info.nextWaypoint)
  }
}
