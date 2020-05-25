import SwiftDux
import SwiftUI

/// Reads the current routing information relative to the view.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteReader<Content>: ConnectableView where Content: View {
  @Environment(\.waypoint) private var waypoint
  @MappedDispatch() private var dispatch

  private var isDetail: Bool?
  private var content: (RouteInfo) -> Content

  /// Initiate a new RouteReader.
  ///
  /// - Parameters:
  ///   - isDetail: Read  from the detail route.
  ///   - content: The contents of the route.
  public init(isDetail: Bool? = nil, content: @escaping (RouteInfo) -> Content) {
    self.isDetail = isDetail
    self.content = content
  }

  public struct Props: Equatable {
    var useRootDetail: Bool
    var route: NavigationState.Route
    var path: String?
    var completed: Bool
    var animate: Bool
  }

  public func map(state: NavigationStateRoot) -> Props? {
    guard let scene = waypoint.resolveSceneState(in: state) else { return nil }
    let useRootDetail = isDetail == true && !waypoint.isDetail
    let route = waypoint.isDetail || useRootDetail ? scene.detailRoute : scene.route
    return Props(
      useRootDetail: useRootDetail,
      route: route,
      path: useRootDetail ? route.legsByPath[waypoint.path]?.path : "/",
      completed: route.completed,
      animate: scene.animate
    )
  }

  public func body(props: Props) -> some View {
    let waypoint = props.useRootDetail ? Waypoint(isDetail: true) : self.waypoint
    let leg = props.route.legsByPath[waypoint.path]
    return content(
      RouteInfo(
        waypoint: waypoint,
        fullPath: props.route.path,
        legs: props.route.legsByPath,
        completed: props.route.completed,
        animate: props.animate,
        active: leg != nil || waypoint.path == props.route.path
      )
    )
  }
}

/// Information about the current route.
public struct RouteInfo {
  /// The waypoint of the view.
  public var waypoint: Waypoint

  /// The full path of the current route.
  public var fullPath: String

  public var legs: [String: NavigationState.RouteLeg]

  /// If the routing has completed.
  public var completed: Bool

  /// If the routing is animating.
  public var animate: Bool

  /// If the routing is active.
  public var active: Bool

  /// The current component of the waypoint if it's active.
  public var path: String {
    waypoint.path
  }

  public var isLastLeg: Bool {
    nextPath == fullPath
  }

  /// The current component of the waypoint if it's active.
  public var nextPath: String? {
    legs[path]?.path
  }

  /// The current component of the waypoint if it's active.
  public var component: String? {
    legs[path]?.component
  }

  /// The current component of the waypoint if it's active.
  public var nextComponent: String? {
    guard let nextPath = nextPath else { return nil }
    return legs[nextPath]?.component
  }

  func component<T>(as type: T.Type) -> T? where T: LosslessStringConvertible {
    component.flatMap { T($0) }
  }

  func nextComponent<T>(as type: T.Type) -> T? where T: LosslessStringConvertible {
    nextComponent.flatMap { T($0) }
  }
}

/// Convenience for views that rely on routing information.
public protocol RouteReaderView: View {
  associatedtype Content: View
  var isDetail: Bool? { get }

  /// The body of the view.
  /// - Parameter routeInfo: The current routing information.
  /// - Returns: The view.
  func body(routeInfo: RouteInfo) -> Content
}

extension RouteReaderView {
  public var isDetail: Bool? { nil }

  public var body: RouteReader<Content> {
    RouteReader(isDetail: isDetail, content: body)
  }
}

/// Convenience for view modifiers that rely on routing information.
public protocol RouteReaderViewModifier: ViewModifier {
  associatedtype RouteReaderContent: View
  var isDetail: Bool? { get }

  /// The body of the view.
  /// - Parameters:
  ///   - content: The content to modify.
  ///   - routeInfo: The current routing information.
  /// - Returns: The view.
  func body(content: Content, routeInfo: RouteInfo) -> RouteReaderContent
}

extension RouteReaderViewModifier {
  public var isDetail: Bool? { nil }

  public func body(content: Content) -> RouteReader<RouteReaderContent> {
    RouteReader(isDetail: isDetail) { self.body(content: content, routeInfo: $0) }
  }
}
