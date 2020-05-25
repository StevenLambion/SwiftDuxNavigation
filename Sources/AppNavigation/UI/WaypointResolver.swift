import SwiftDux
import SwiftUI

/// Resolves the routing of a waypoint.
///
/// This is used by custom navigational waypoint views to resolve their routing information.
public struct WaypointResolver<Content>: RouteReaderView where Content: View {
  @MappedDispatch() private var dispatch

  public var isDetail: Bool?

  private var name: String?
  private var hasPathParameter: Bool
  private var defaultPathParameter: String?
  private var content: (ResolvedWaypointInfo) -> Content

  // swift-format-ignore: ValidateDocumentationComments

  /// Initialize new `WaypointResolver`
  /// - Parameters:
  ///   - name: An optional name of the waypoint.
  ///   - hasPathParameter: If the waypoint accepts a path parameter.
  ///   - defaultPathParameter: A default path parameter if one is not included in the current route path.
  ///   - isDetail: Force the waypoint to resolve from  the detail route instead of its parent's route.
  ///   - content: The content of the waypoint.
  public init(
    name: String? = nil,
    hasPathParameter: Bool = false,
    defaultPathParameter: String? = nil,
    isDetail: Bool? = nil,
    @ViewBuilder content: @escaping (ResolvedWaypointInfo) -> Content
  ) {
    self.name = name
    self.hasPathParameter = hasPathParameter
    self.defaultPathParameter = defaultPathParameter
    self.isDetail = isDetail
    self.content = content
  }

  public func body(info: RouteInfo) -> some View {
    let pathParameter = resolvePathParameter(from: info)
    let waypoint = resolveWaypoint(from: info)
    let active = isActive(pathParameter: pathParameter, info: info)
    let redirect = shouldRedirect(pathParameter: pathParameter, info: info)
    let nextWaypoint = pathParameter.map { waypoint.next(with: $0) } ?? waypoint
    let resolvedWaypointInfo = ResolvedWaypointInfo(
      waypoint: waypoint,
      nextWaypoint: nextWaypoint,
      pathParameter: pathParameter,
      active: active,
      animate: info.animate,
      completed: info.completed
    )
    if redirect {
      dispatch(waypoint.navigate(to: defaultPathParameter!, animate: info.animate))
    } else if active && !info.completed && nextWaypoint.path == info.fullPath {
      dispatch(nextWaypoint.completeNavigation())
    }
    return content(resolvedWaypointInfo).id(waypoint.path)
  }

  /// Determine if the waypoint is active baed on its path parameter configuration.
  ///
  /// - Parameter pathParameter: The current path parameter.
  /// - Returns: True if active.
  private func isPathParameterActive(pathParameter: String?) -> Bool {
    !hasPathParameter || pathParameter != nil
  }

  /// Determine if the waypoint is active based on its configuration.
  ///
  /// - Parameters:
  ///   - pathParameter: The current path parameter.
  ///   - info: The routing information.
  /// - Returns: True if the waypoint is active.
  private func isActive(pathParameter: String?, info: RouteInfo) -> Bool {
    info.active && (name == nil || info.component == name) && isPathParameterActive(pathParameter: pathParameter)
  }

  /// Determine if the waypoint should redirect. This occurs if the waypoint is active, but the route state is missing
  /// the path parameter. It will redirect using the default path parameter.
  ///
  /// - Parameters:
  ///   - pathParameter: The current path parameter.
  ///   - info: The routing information.
  /// - Returns: True if it should redirect.
  private func shouldRedirect(pathParameter: String?, info: RouteInfo) -> Bool {
    info.active && !isPathParameterActive(pathParameter: pathParameter) && defaultPathParameter != nil
  }

  // swift-format-ignore: ValidateDocumentationComments

  /// Resolves the current path parameter
  ///
  /// - Parameter info: The routing information.
  /// - Returns: The current path parameter.
  private func resolvePathParameter(from info: RouteInfo) -> String? {
    guard hasPathParameter else { return nil }
    return name == nil ? info.component : info.nextComponent
  }

  /// Resolves the current waypoint for the contents of the resolver.
  ///
  /// - Parameter info: The routing information.
  /// - Returns: The waypoint.
  private func resolveWaypoint(from info: RouteInfo) -> Waypoint {
    if let name = name {
      return info.waypoint.next(with: name)
    }
    return info.waypoint
  }
}

/// Resolved Information about the current waypoint.
public struct ResolvedWaypointInfo {

  /// The current waypoint.
  public var waypoint: Waypoint

  /// The next child waypoint. It will etiher represent the path parameter
  /// or match the current waypoint if there isn't a path parameter.
  public var nextWaypoint: Waypoint

  /// The resolved path parameter.
  public var pathParameter: String?

  /// If the waypoint is active.
  public var active: Bool

  /// If the waypoint should animate its transition.
  public var animate: Bool

  // If the waypoint's route is completed.
  public var completed: Bool

  /// Get the path parameter as a specific type.
  ///
  /// - Parameter type: The type to convert to.
  /// - Returns: The converted path parameter.
  public func pathParameter<T>(as type: T.Type) -> T? where T: LosslessStringConvertible {
    pathParameter.flatMap { T($0) }
  }
}

/// Convenience for waypoint views.
public protocol WaypointResolverView: View {
  associatedtype Content: View
  static var hasPathParameter: Bool { get }
  var defaultPathParameter: String? { get }
  var name: String? { get }
  var isDetail: Bool? { get }

  /// The body of the view.
  /// 
  /// - Parameter info: The resolved waypoint information.
  /// - Returns: The view.
  func body(info: ResolvedWaypointInfo) -> Content
}

extension WaypointResolverView {
  public static var hasPathParameter: Bool { false }
  public var defaultPathParameter: String? { nil }
  public var name: String? { nil }
  public var isDetail: Bool? { nil }

  public var body: WaypointResolver<Content> {
    WaypointResolver(
      name: name,
      hasPathParameter: type(of: self).hasPathParameter,
      defaultPathParameter: defaultPathParameter,
      isDetail: isDetail,
      content: body
    )
  }
}

/// Convenience for view modifiers that represent waypoints.
public protocol WaypointResolverViewModifier: ViewModifier {
  associatedtype WaypointResolverContent: View
  static var hasPathParameter: Bool { get }
  var defaultPathParameter: String? { get }
  var name: String? { get }
  var isDetail: Bool? { get }

  /// The body of the view.
  ///
  /// - Parameters:
  ///   - content: The content to modify.
  ///   - info: The resolved waypoint information.
  /// - Returns: The view.
  func body(content: Content, info: ResolvedWaypointInfo) -> WaypointResolverContent
}

extension WaypointResolverViewModifier {
  public static var hasPathParameter: Bool { false }
  public var defaultPathParameter: String? { nil }
  //public var name: String? { nil }
  public var isDetail: Bool? { nil }

  public func body(content: Content) -> WaypointResolver<WaypointResolverContent> {
    WaypointResolver(
      name: name,
      hasPathParameter: Self.hasPathParameter,
      defaultPathParameter: defaultPathParameter,
      isDetail: isDetail
    ) {
      self.body(content: content, info: $0)
    }
  }
}
