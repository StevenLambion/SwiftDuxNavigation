import SwiftDux
import SwiftUI

public enum WaypointType {
  case empty
  case name(String)
  case parameter(defaultValue: CustomStringConvertible? = nil)
  case predicate((String?) -> Bool)
}

/// Resolves the routing of a waypoint.
///
/// This is used by custom navigational waypoint views to resolve their routing information.
public struct WaypointView<Content>: ConnectableView where Content: View {
  @Environment(\.waypoint) private var sourceWaypoint
  @Environment(\.actionDispatcher) private var dispatch

  public var isDetail: Bool?
  public var type: WaypointType
  public var content: (Waypoint) -> Content

  private var defaultValue: String? {
    switch type {
    case .parameter(let value):
      return value?.description
    default:
      return nil
    }
  }

  // swift-format-ignore: ValidateDocumentationComments

  /// Initialize new `WaypointResolver`
  /// - Parameters:
  ///   - name: An optional name of the waypoint.
  ///   - hasPathParameter: If the waypoint accepts a path parameter.
  ///   - defaultPathParameter: A default path parameter if one is not included in the current route path.
  ///   - isDetail: Force the waypoint to resolve from  the detail route instead of its parent's route.
  ///   - content: The content of the waypoint.
  public init(
    _ type: WaypointType,
    isDetail: Bool? = nil,
    @ViewBuilder content: @escaping (Waypoint) -> Content
  ) {
    self.type = type
    self.isDetail = isDetail
    self.content = content
  }

  public struct Props: Equatable {
    var leg: NavigationState.RouteLeg?
    var fullPath: String
    @ActionBinding var destination: String?
    @ActionBinding var isActive: Bool

    public static func == (lhs: Props, rhs: Props) -> Bool {
      lhs.leg == rhs.leg && lhs.isActive == rhs.isActive
    }
  }

  public func map(state: NavigationStateRoot, binder: ActionBinder) -> Props? {
    let route = sourceWaypoint.resolveRouteState(in: state)
    let leg = sourceWaypoint.resolveLegState(in: state)
    let destination = leg?.destination ?? defaultValue
    return Props(
      leg: leg,
      fullPath: route?.path ?? "",
      destination: binder.bind(destination) { nextDestination in
        guard nextDestination != destination else { return nil }
        return sourceWaypoint.navigate(to: nextDestination, isDetail: isDetail)
      },
      isActive: binder.bind(isActive(destination: destination)) { active in
        guard let path = leg?.path else { return nil }
        return NavigationAction.toggle(
          path: path,
          inRoute: sourceWaypoint.routeName,
          isDetail: isDetail ?? sourceWaypoint.isDetail,
          skipIfAncestor: false,
          isActive: active
        )
      }
    )
  }

  public func body(props: Props) -> some View {
    let waypoint = Waypoint(
      routeName: sourceWaypoint.routeName,
      path: props.destination.flatMap { $0.standardizedPath(withBasePath: sourceWaypoint.path) } ?? sourceWaypoint.path,
      isDetail: isDetail ?? sourceWaypoint.isDetail,
      isActive: props.$isActive,
      destination: props.$destination
    )

    if props.leg?.path == props.fullPath {
      dispatch(waypoint.completeNavigation())
    }

    return content(waypoint).onAppear {
      guard !props.isActive,
        let value = defaultValue
      else { return }

      dispatch(sourceWaypoint.navigate(to: value))
    }
  }

  private func isActive(destination: String?) -> Bool {
    switch type {
    case .empty:
      return destination == nil
    case .name(let value):
      return destination == value
    case .parameter:
      return !(destination?.isEmpty ?? true)
    case .predicate(let predicate):
      return predicate(destination)
    }
  }
}
