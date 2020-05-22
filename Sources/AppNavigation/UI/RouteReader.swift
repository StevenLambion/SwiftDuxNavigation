import SwiftDux
import SwiftUI

/// Reads the current routing information relative to the view.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteReader<Content>: ConnectableView where Content: View {
  @Environment(\.waypoint) private var waypoint
  @MappedDispatch() private var dispatch

  private var content: (RouteInfo) -> Content

  /// Initiate a new RouteReader.
  ///
  /// - Parameter content: The contents of the route.
  public init(content: @escaping (RouteInfo) -> Content) {
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
    guard let route = waypoint.resolveState(in: state) else { return nil }
    return Props(
      route: route,
      path: route.legsByPath[waypoint.path]?.path,
      shouldComplete: !route.completed && waypoint.path == route.lastLeg.parentPath
    )
  }

  public func body(props: Props) -> some View {
    let leg = props.route.legsByPath[waypoint.path]
    if props.shouldComplete {
      self.dispatch(self.waypoint.completeNavigation())
    }
    return content(
      RouteInfo(
        waypoint: waypoint,
        pathParameter: leg?.component,
        path: props.route.path,
        isLastWaypoint: leg?.path == props.route.path
      )
    )
  }
}

/// Information about the current route.
public struct RouteInfo {
  /// The waypoint of the view.
  public var waypoint: Waypoint

  /// The current path parameter of the waypoint if it's active.
  public var pathParameter: String?

  /// The full path of the current route.
  public var path: String

  /// If the waypoint is the final destination.
  public var isLastWaypoint: Bool
}

/// Convenience for views that rely on routing information.
public protocol RouteReaderView: View {
  associatedtype Content: View

  /// The body of the view.
  /// - Parameter routeInfo: The current routing information.
  /// - Returns: The view.
  func body(routeInfo: RouteInfo) -> Content
}

extension RouteReaderView {

  public var body: RouteReader<Content> {
    RouteReader(content: body)
  }
}

/// Convenience for view modifiers that rely on routing information.
public protocol RouteReaderViewModifier: ViewModifier {
  associatedtype RouteReaderContent: View

  /// The body of the view.
  /// - Parameters:
  ///   - content: The content to modify.
  ///   - routeInfo: The current routing information.
  /// - Returns: The view.
  func body(content: Content, routeInfo: RouteInfo) -> RouteReaderContent
}

extension RouteReaderViewModifier {

  public func body(content: Content) -> RouteReader<RouteReaderContent> {
    RouteReader { self.body(content: content, routeInfo: $0) }
  }
}
