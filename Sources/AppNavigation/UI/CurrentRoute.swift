import SwiftDux
import SwiftUI

/// Relative routing information that is injected into the environment.
public struct CurrentRoute {

  /// The scene name.
  public var sceneName: String = SceneState.mainSceneName

  /// The active path relative to the view.
  public var path: String = "/"

  public var isDetail: Bool = false

  public var isBranch: Bool = false

  public var isRoot: Bool {
    path == "/"
  }

  /// Resolve the `SceneState` relative to the view from the application state.
  /// - Parameter state: The application state.
  /// - Returns: The `SceneState`.
  public func resolveSceneState(in state: NavigationStateRoot) -> SceneState? {
    state.navigation.sceneByName[sceneName]
  }

  /// Resolve the `RouteState` relative to the view from the application state.
  /// - Parameter state: The application state.
  /// - Returns: The `RouteState`.
  public func resolveState(in state: NavigationStateRoot) -> RouteState? {
    if isDetail {
      return resolveSceneState(in: state)?.detailRoute
    }
    return resolveSceneState(in: state)?.route
  }

  /// Get the next RouteInfo object for the provided component.
  /// - Parameters:
  ///   - component: The next component
  ///   - isBranch: Indicates if the next route is a branch of a route.
  /// - Returns: A new `RouteInfo`
  public func next<T>(with component: T, isBranch: Bool = false) -> CurrentRoute where T: LosslessStringConvertible {
    CurrentRoute(
      sceneName: sceneName,
      path: "\(path)\(component)/",
      isDetail: isDetail,
      isBranch: isBranch
    )
  }

  /// Standardizes a relative path off the route's path.
  /// - Parameter path: The path to standardize.
  /// - Returns: The standardized path.
  public func standardizedPath(forPath path: String) -> String? {
    path.standardizedPath(withBasePath: isDetail ? path : "/")
  }

  /// Navigate relative to current route.
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - scene: The scene to perform the navigation in.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - animate: Animate the anvigation.
  /// - Returns: A navigation action.
  public func navigate(to path: String, inScene scene: String? = nil, isDetail isDetailOverride: Bool = false, animate: Bool = true) -> Action {
    guard let absolutePath = standardizedPath(forPath: path) else { return EmptyAction() }
    return NavigationAction.navigate(to: absolutePath, inScene: scene ?? sceneName, isDetail: self.isDetail || isDetailOverride, animate: animate)
  }

  /// Pop to a path above the current route if it exists.
  /// - Parameters:
  ///   - path: The path to navigate to.
  ///   - scene: The scene to perform the navigation in.
  ///   - isDetailOverride: Navigate in the detail route.
  ///   - preserveBranch: Preserve the branch of the path.
  ///   - animate: Animate the anvigation.
  /// - Returns: A navigation action.
  public func pop(to path: String, inScene scene: String? = nil, isDetail isDetailOverride: Bool = false, preserveBranch: Bool = false, animate: Bool = true)
    -> Action
  {
    guard let absolutePath = standardizedPath(forPath: path) else { return EmptyAction() }
    return NavigationAction.pop(
      to: absolutePath,
      inScene: scene ?? sceneName,
      isDetail: self.isDetail || isDetailOverride,
      preserveBranch: preserveBranch,
      animate: animate
    )
  }

  /// Manually complete the navigation.
  /// - Parameter isDetailOverride: Complete in the detail route.
  /// - Returns: A navigation action.
  public func completeNavigation(isDetail isDetailOverride: Bool = false) -> Action {
    return NavigationAction.completeRouting(scene: sceneName, isDetail: isDetail || isDetailOverride)
  }
}

public final class CurrentRouteKey: EnvironmentKey {
  public static var defaultValue = CurrentRoute(sceneName: SceneState.mainSceneName, path: "/")
}

extension EnvironmentValues {

  /// Information on the current route relative to the view.
  public var currentRoute: CurrentRoute {
    get { self[CurrentRouteKey] }
    set { self[CurrentRouteKey] = newValue }
  }
}

extension View {

  /// Specify a new scene for the current route.
  /// - Parameter name: The name of the scene.
  /// - Returns: The view.
  public func scene(named name: String) -> some View {
    self.environment(\.currentRoute, CurrentRoute(sceneName: name, path: "/"))
  }
}
