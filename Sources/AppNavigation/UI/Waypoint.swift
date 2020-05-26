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

  // Is the waypoint the root of the route.
  public var isRoot: Bool {
    path == "/"
  }

  /// Resolve the `Scene` relative to the view from the application state.
  /// 
  /// - Parameter state: The application state.
  /// - Returns: The `Scene`.
  public func resolveScene(in state: NavigationStateRoot) -> NavigationState.Scene? {
    state.navigation.sceneByName[sceneName]
  }

  /// Resolve the `Route` relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  /// - Returns: The `Route`.
  public func resolveRoute(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil) -> NavigationState.Route? {
    let isDetail = self.isDetail || isDetailOverride == true
    if isDetail {
      return resolveScene(in: state)?.detailRoute
    }
    return resolveScene(in: state)?.route
  }

  /// Resolve the `RouteLeg` relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  /// - Returns: The `RouteLeg`.
  public func resolveLeg(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil) -> NavigationState.RouteLeg? {
    resolveRoute(in: state, isDetail: isDetailOverride)?.legsByPath[path]
  }

  /// Resolve the path component of the waypoint relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  /// - Returns: The `RouteLeg`.
  public func resolveComponent(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil) -> String? {
    resolveLeg(in: state, isDetail: isDetailOverride)?.component
  }

  /// Resolve the path component of the waypoint relative to the view from the application state.
  ///
  /// - Parameters:
  ///   - state: The application state.
  ///   - isDetailOverride: Get the detail route.
  ///   - type: The type to convert the component to.
  /// - Returns: The `RouteLeg`.
  public func resolveComponent<T>(in state: NavigationStateRoot, isDetail isDetailOverride: Bool? = nil, as type: T.Type) -> T?
  where T: LosslessStringConvertible {
    resolveLeg(in: state, isDetail: isDetailOverride).flatMap { T($0.component) }
  }

  /// Get the next Waypoint object for the provided component.
  ///
  /// - Parameter component: The next component.
  /// - Returns: A new `Waypoint`
  public func next<T>(with component: T) -> Waypoint where T: LosslessStringConvertible {
    return Waypoint(
      sceneName: sceneName,
      path: "\(path)\(component)/",
      isDetail: isDetail
    )
  }

  /// Navigate relative to current route.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - scene: The scene to perform the navigation in.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - skipIfAncestor: Prevents the route from changing if the next path is an ancestor.
  ///   - animate: Animate the anvigation.
  /// - Returns: A navigation action.
  public func navigate<T>(to path: T, inScene scene: String? = nil, isDetail isDetailOverride: Bool? = nil, skipIfAncestor: Bool = false, animate: Bool = true)
    -> ActionPlan<NavigationStateRoot> where T: LosslessStringConvertible
  {
    let path = String(path)
    let isDetailForPath = isDetailOverride ?? self.isDetail
    guard let absolutePath = standardizedPath(forPath: path, notRelative: isDetailForPath != isDetail) else {
      return ActionPlan { _ in }
    }
    return NavigationAction.navigate(to: absolutePath, inScene: scene ?? sceneName, isDetail: isDetailForPath, skipIfAncestor: skipIfAncestor, animate: animate)
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

  public func shouldComplete(for route: NavigationState.Route) -> Bool {
    !route.completed && path == route.lastLeg.parentPath
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

internal final class WaypointKey: EnvironmentKey {
  public static var defaultValue = Waypoint(sceneName: NavigationState.Scene.defaultName, path: "/")
}

extension EnvironmentValues {

  /// The waypoint of the view.
  public var waypoint: Waypoint {
    get { self[WaypointKey] }
    set { self[WaypointKey] = newValue }
  }
}

extension View {

  /// Specify a new scene for the current route.
  ///
  /// - Parameter name: The name of the scene.
  /// - Returns: The view.
  public func scene(_ name: String) -> some View {
    self.environment(\.waypoint, Waypoint(sceneName: name, path: "/"))
  }

  /// Set the view as the next waypoint.
  ///
  /// - Parameter waypoint: Pass a custom waypoint to use.
  /// - Returns: The view
  public func waypoint(with waypoint: Waypoint?) -> some View {
    self.transformEnvironment(\.waypoint) {
      guard var waypoint = waypoint else { return }
      waypoint.sceneName = $0.sceneName
      $0 = waypoint
    }
  }

  /// Set the view as the next waypoint.
  ///
  /// - Parameter component: The component, or name, of the waypoint.
  /// - Returns: The view
  public func waypoint<T>(with component: T) -> some View where T: LosslessStringConvertible {
    self.transformEnvironment(\.waypoint) {
      $0 = $0.next(with: component)
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
