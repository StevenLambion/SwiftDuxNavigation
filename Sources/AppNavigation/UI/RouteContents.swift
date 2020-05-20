import SwiftDux
import SwiftUI

/// Place above the contents of a route.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteContents<Content>: ConnectableView where Content: View {
  @Environment(\.currentRoute) private var currentRoute
  @MappedDispatch() private var dispatch

  private var content: (RouteInfo) -> Content

  /// Initiate a new RouteContents.
  /// - Parameter content: The contents of the route.
  public init(@ViewBuilder content: @escaping (RouteInfo) -> Content) {
    self.content = content
  }

  public struct Props: Equatable {
    var route: NavigationState.Route
    var path: String?
    var shouldComplete: Bool

    public static func == (lhs: Props, rhs: Props) -> Bool {
      lhs.path == rhs.path && lhs.shouldComplete == rhs.shouldComplete
    }
  }

  public func map(state: NavigationStateRoot) -> Props? {
    guard let route = currentRoute.resolveState(in: state) else { return nil }
    return Props(
      route: route,
      path: route.legsByPath[currentRoute.path]?.path,
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
    return content(
      RouteInfo(
        current: currentRoute,
        path: leg?.path,
        pathParameter: leg?.component,
        fullPath: props.route.path,
        isLastLeg: leg?.path == props.route.path
      )
    )
  }
}

public struct RouteInfo {
  public var current: CurrentRoute
  public var path: String?
  public var pathParameter: String?
  public var fullPath: String
  public var isLastLeg: Bool
}
