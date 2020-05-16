import SwiftDux
import SwiftUI

/// Place above the contents of a route.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteContents<Content>: ConnectableView where Content: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  private var content: (RouteInfo, RouteLeg?, RouteState) -> Content

  /// Initiate a new RouteContents.
  /// - Parameter content: The contents of the route.
  public init(@ViewBuilder content: @escaping (RouteInfo, RouteLeg?, RouteState) -> Content) {
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
    guard let route = routeInfo.resolve(in: state) else { return nil }
    return Props(
      route: route,
      leg: route.legsByPath[routeInfo.path],
      shouldComplete: !route.completed && routeInfo.path == route.lastLeg.parentPath
    )
  }

  public func body(props: Props) -> some View {
    if props.shouldComplete {
      self.dispatch(NavigationAction.completeRouting(scene: self.routeInfo.sceneName))
    }
    // Use latest route info in case a parent view changed it during the current SwiftUI update.
    return content(routeInfo, props.route.legsByPath[routeInfo.path], props.route)
  }
}
