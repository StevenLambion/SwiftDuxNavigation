import SwiftDux
import SwiftUI

/// Place above the contents of a route.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteContents<Content>: ConnectableView where Content: View {
  @Environment(\.currentRoute) private var currentRoute
  @MappedDispatch() private var dispatch

  private var content: (CurrentRoute, RouteLeg?, RouteState) -> Content

  /// Initiate a new RouteContents.
  /// - Parameter content: The contents of the route.
  public init(@ViewBuilder content: @escaping (CurrentRoute, RouteLeg?, RouteState) -> Content) {
    self.content = content
  }

  public struct Props: Equatable {
    var route: RouteState
    var leg: RouteLeg?
    var shouldComplete: Bool

    public static func == (lhs: Props, rhs: Props) -> Bool {
      lhs.leg == rhs.leg && lhs.shouldComplete == rhs.shouldComplete
    }
  }

  public func map(state: NavigationStateRoot) -> Props? {
    guard let route = currentRoute.resolveState(in: state) else { return nil }
    return Props(
      route: route,
      leg: route.legsByPath[currentRoute.path],
      shouldComplete: !route.completed && currentRoute.path == route.lastLeg.parentPath
    )
  }

  public func body(props: Props) -> some View {
    // Use latest route info in case a parent view changed it during the current SwiftUI update.
    return content(currentRoute, props.route.legsByPath[currentRoute.path], props.route).onAppear {
      if props.shouldComplete {
        self.dispatch(self.currentRoute.completeNavigation())
      }
    }
  }
}
