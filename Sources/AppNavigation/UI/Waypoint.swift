import SwiftDux
import SwiftUI

/// A waypoint within a route.

/// The user is always within a single waypoint per route.
public struct Waypoint: Equatable {

  /// The scene name.
  public var sceneName: String = NavigationState.Scene.defaultName

  /// The active path relative to the view.
  public var path: String = "/"

  ///Is the waypoint in the detial route.
  public var isDetail: Bool = false

  /// Is the waypoint a branch of its parent waypoint.
  public var isBranch: Bool = false

  // Is the waypoint the root of the route.
  public var isRoot: Bool {
    path == "/"
  }

  /// Resolve the `Scene` relative to the view from the application state.
  /// 
  /// - Parameter state: The application state.
  /// - Returns: The `Scene`.
  public func resolveSceneState(in state: NavigationStateRoot) -> NavigationState.Scene? {
    state.navigation.sceneByName[sceneName]
  }

  /// Resolve the `Route` relative to the view from the application state.
  ///
  /// - Parameter state: The application state.
  /// - Returns: The `Route`.
  public func resolveState(in state: NavigationStateRoot) -> NavigationState.Route? {
    if isDetail {
      return resolveSceneState(in: state)?.detailRoute
    }
    return resolveSceneState(in: state)?.route
  }

  /// Get the next RouteInfo object for the provided component.
  ///
  /// - Parameters:
  ///   - component: The next component
  ///   - isBranch: Indicates if the next route is a branch of a route.
  /// - Returns: A new `RouteInfo`
  public func next<T>(with component: T, isBranch: Bool = false) -> Waypoint where T: LosslessStringConvertible {
    Waypoint(
      sceneName: sceneName,
      path: "\(path)\(component)/",
      isDetail: isDetail,
      isBranch: isBranch
    )
  }

  /// Navigate relative to current route.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - scene: The scene to perform the navigation in.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - animate: Animate the anvigation.
  /// - Returns: A navigation action.
  public func navigate(to path: String, inScene scene: String? = nil, isDetail isDetailOverride: Bool? = nil, animate: Bool = true)
    -> Action
  {
    let isDetailForPath = isDetailOverride ?? self.isDetail
    guard let absolutePath = standardizedPath(forPath: path, notRelative: isDetailForPath != isDetail) else { return EmptyAction() }
    return NavigationAction.navigate(to: absolutePath, inScene: scene ?? sceneName, isDetail: isDetailForPath, animate: animate)
  }

  /// Pop to a path above the current route if it exists.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - scene: The scene to perform the navigation in.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - preserveBranch: Preserve the branch of the path.
  ///   - animate: Animate the anvigation.
  /// - Returns: A navigation action.
  public func pop(to path: String, inScene scene: String? = nil, isDetail isDetailOverride: Bool? = nil, preserveBranch: Bool = false, animate: Bool = true)
    -> Action
  {
    let isDetailForPath = isDetailOverride ?? self.isDetail
    guard let absolutePath = standardizedPath(forPath: path, notRelative: isDetailForPath != isDetail) else { return EmptyAction() }
    return NavigationAction.pop(
      to: absolutePath,
      inScene: scene ?? sceneName,
      isDetail: isDetailForPath,
      preserveBranch: preserveBranch,
      animate: animate
    )
  }

  /// Manually complete the navigation.
  ///
  /// - Parameter isDetailOverride: Complete in the detail route.
  /// - Returns: A navigation action.
  public func completeNavigation(isDetail isDetailOverride: Bool = false) -> Action {
    return NavigationAction.completeRouting(scene: sceneName, isDetail: isDetail || isDetailOverride)
  }

  /// Begin caching the route's children.
  ///
  /// - Parameter policy: The caching policy to use.
  /// - Returns: The action.
  public func beginCaching(policy: NavigationState.RouteCachingPolicy = .whileActive) -> Action {
    NavigationAction.beginCaching(path: path, scene: sceneName, isDetail: isDetail, policy: policy)
  }

  /// Stop caching the route's children.
  ///
  /// - Returns: The action.
  public func stopCaching() -> Action {
    NavigationAction.stopCaching(path: path, scene: sceneName, isDetail: isDetail)
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

public final class CurrentRouteKey: EnvironmentKey {
  public static var defaultValue = Waypoint(sceneName: NavigationState.Scene.defaultName, path: "/")
}

extension EnvironmentValues {

  /// The waypoint of the view.
  public var waypoint: Waypoint {
    get { self[CurrentRouteKey] }
    set { self[CurrentRouteKey] = newValue }
  }
}

extension View {

  /// Specify a new scene for the current route.
  ///
  /// - Parameter name: The name of the scene.
  /// - Returns: The view.
  public func scene(named name: String) -> some View {
    self.environment(\.waypoint, Waypoint(sceneName: name, path: "/"))
  }
  
  /// Set the view as the next waypoint.
  ///
  /// - Parameter waypoint: Pass a custom waypoint to use.
  /// - Returns: The view
  public func nextWaypoint(with waypoint: Waypoint) -> some View {
    self.transformEnvironment(\.waypoint) {
      var waypoint = waypoint
      waypoint.sceneName = $0.sceneName
      $0 = waypoint
    }
  }
  
  /// Set the view as the next waypoint.
  ///
  /// - Parameters:
  ///   - component: The component, or name, of the waypoint.
  ///   - isBranch: Indicates the waypoint is a child branch of a parent waypoint.
  /// - Returns: The view
  public func nextWaypoint<T>(with component: T?, isBranch: Bool = false) -> some View where T: LosslessStringConvertible {
    self.transformEnvironment(\.waypoint) {
      guard let component = component else { return }
      $0 = $0.next(with: component, isBranch: isBranch)
    }
  }
  
  /// Resets the route by applying a root waypoint.
  ///
  /// This should only be used to indicate the detail route's root waypoint.
  /// - Parameters:
  ///   - path: The root path of the route.
  ///   - isDetail: If it's for the detail route.
  /// - Returns: The view
  public func resetRoute(with path: String, isDetail: Bool = false) -> some View {
    self.transformEnvironment(\.waypoint) {
      $0 = Waypoint(sceneName: $0.sceneName, path: path, isDetail: isDetail)
    }
  }
}