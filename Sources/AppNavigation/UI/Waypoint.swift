import Foundation
import SwiftDux
import SwiftUI

/// Represents the destination of a route leg.
public struct Waypoint {

  /// The route name.
  public var routeName: String = NavigationState.defaultRouteName

  /// The full path of the route leg when active.
  public var path: String = "/"

  ///Indicates if the waypoint is on the detail route.
  public var isDetail: Bool = false

  /// Indicates if the waypoint is active.
  @Binding public var isActive: Bool

  /// The destination name of the waypoint when the leg is active.
  /// This may be a constant value or a dynamic parameter value depending on the type of destination.
  @Binding public var destination: String?

  /// Safely converts the destination string to the given type.
  ///
  /// If the binding cannot convert the value, it returns nil.
  /// - Parameter type: The type
  /// - Returns: The typed binding.
  public func destination<T>(as type: T.Type) -> Binding<T?> where T: LosslessStringConvertible {
    return Binding(
      get: { T(destination ?? "") },
      set: { $destination.wrappedValue = $0?.description }
    )
  }

  /// Resolve the `Route` relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  /// - Returns: The `Route`.
  public func resolveRouteState(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil) -> NavigationState.RouteState? {
    let isDetail = self.isDetail || isDetailOverride == true
    return isDetail ? state.navigation.detailRouteByName[routeName] : state.navigation.primaryRouteByName[routeName]
  }

  /// Resolve the `RouteLeg` relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  /// - Returns: The `RouteLeg`.
  public func resolveLegState(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil) -> NavigationState.RouteLeg? {
    resolveRouteState(in: state, isDetail: isDetailOverride)?.legBySourcePath[path]
  }

  /// Navigate relative to current route.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - routeName: The name of the route to navigate.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - skipIfAncestor: Prevents the route from changing if the next path is an ancestor.
  /// - Returns: A navigation action.
  public func navigate<T>(
    to path: T? = nil,
    inRoute routeName: String? = nil,
    isDetail isDetailOverride: Bool? = nil,
    skipIfAncestor: Bool = false
  )
    -> Action where T: LosslessStringConvertible
  {
    let path = path.flatMap { $0.description } ?? "."
    let isDetailForPath = isDetailOverride ?? self.isDetail
    guard let absolutePath = standardizedPath(forPath: path, notRelative: isDetailForPath != isDetail) else {
      return EmptyAction()
    }
    return NavigationAction.navigate(to: absolutePath, inRoute: routeName ?? self.routeName, isDetail: isDetailForPath, skipIfAncestor: skipIfAncestor)
  }

  /// Navigate relative to current route.
  ///
  /// - Parameter isActive: Toggles the active state of the waypoint.
  /// - Returns: A navigation action.
  public func toggle(isActive: Bool) -> Action {
    NavigationAction.toggle(
      path: path,
      inRoute: routeName,
      isDetail: isDetail,
      isActive: isActive
    )
  }

  /// Manually complete the navigation.
  ///
  /// - Parameter isDetailOverride: Complete in the detail route.
  /// - Returns: A navigation action.
  public func completeNavigation(isDetail isDetailOverride: Bool = false) -> Action {
    return NavigationAction.completeRouting(routeName: routeName, isDetail: isDetail || isDetailOverride)
  }

  /// Begin caching the route's children.
  ///
  /// - Parameter policy: The caching policy to use.
  /// - Returns: The action.
  public func beginCaching(policy: NavigationState.RouteCachingPolicy = .whileActive) -> Action {
    NavigationAction.beginCaching(path: path, routeName: routeName, isDetail: isDetail, policy: policy)
  }

  /// Stop caching the route's children.
  ///
  /// - Returns: The action.
  public func stopCaching() -> Action {
    NavigationAction.stopCaching(path: path, routeName: routeName, isDetail: isDetail)
  }

  /// Standardizes a relative path off the route's path.
  ///
  /// - Parameters:
  ///   - relativePath: The path to standardize.
  ///   - notRelative: If the path is not related to the current route.
  /// - Returns: The standardized path.
  private func standardizedPath(forPath relativePath: String, notRelative: Bool) -> String? {
    relativePath.standardizedPath(withBasePath: notRelative ? "/" : self.path)
  }
}

extension Waypoint: Equatable {

  public static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
    lhs.routeName == rhs.routeName
      && lhs.path == rhs.path
      && lhs.isDetail == rhs.isDetail
      && lhs.isActive == rhs.isActive
  }
}

internal final class WaypointKey: EnvironmentKey {
  public static var defaultValue = Waypoint(
    isActive: Binding(get: { true }, set: { _ in }),
    destination: Binding(get: { "" }, set: { _ in })
  )
}

extension EnvironmentValues {

  /// The waypoint of the view.
  public var waypoint: Waypoint {
    get { self[WaypointKey] }
    set { self[WaypointKey] = newValue }
  }
}
