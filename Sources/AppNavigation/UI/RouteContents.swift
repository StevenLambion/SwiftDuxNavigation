import SwiftDux
import SwiftUI

/// Place above the contents of a route.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteContents<Content>: ConnectableView where Content: View {
  @Environment(\.currentRoute) private var currentRoute
  @MappedDispatch() private var dispatch

  private var content: (CurrentRoute, RouteLeg?, RouteState, [String: RouteSnapshot]) -> Content

  /// Initiate a new RouteContents.
  /// - Parameter content: The contents of the route.
  public init(@ViewBuilder content: @escaping (CurrentRoute, RouteLeg?, RouteState, [String: RouteSnapshot]) -> Content) {
    self.content = content
  }

  /// Initiate a new RouteContents.
  /// - Parameter content: The contents of the route.
  public init(@ViewBuilder content: @escaping (CurrentRoute, RouteLeg?, RouteState) -> Content) {
    self.content = { currentRoute, leg, state, _ in content(currentRoute, leg, state) }
  }

  public struct Props: Equatable {
    var route: RouteState
    var leg: RouteLeg?
    var snapshots: [String: RouteSnapshot]
    var shouldComplete: Bool

    public static func == (lhs: Props, rhs: Props) -> Bool {
      lhs.snapshots == rhs.snapshots && lhs.leg == rhs.leg && lhs.shouldComplete == rhs.shouldComplete
    }
  }

  public func map(state: NavigationStateRoot) -> Props? {
    guard let scene = currentRoute.resolveSceneState(in: state) else { return nil }
    guard let route = currentRoute.resolveState(in: state) else { return nil }
    let leg = route.legsByPath[currentRoute.path]
    return Props(
      route: route,
      leg: leg,
      snapshots: scene.snapshots[currentRoute.path] ?? [:],
      shouldComplete: !route.completed && currentRoute.path == route.lastLeg.parentPath
    )
  }

  public func body(props: Props) -> some View {
    let leg = props.route.legsByPath[currentRoute.path]
    if props.shouldComplete {
      DispatchQueue.main.async {
        self.dispatch(self.currentRoute.completeNavigation())
      }
    }
    return content(currentRoute, leg, props.route, props.snapshots)
  }
}
