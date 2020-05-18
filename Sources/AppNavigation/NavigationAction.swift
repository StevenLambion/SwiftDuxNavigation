import Foundation
import SwiftDux
import SwiftUI

/// Navigation actions
public enum NavigationAction: Action {

  /// Remove a scene from state  by name.
  case clearScene(named: String)

  /// Begin routing to a new path.
  case beginRouting(path: String, scene: String, isDetail: Bool, animate: Bool)

  /// Begin popping the navigation to an ancestor path.
  case beginPop(path: String, scene: String, isDetail: Bool, preserveBranch: Bool, animate: Bool)

  /// Complete the navigation routing.
  case completeRouting(scene: String, isDetail: Bool)
}

extension NavigationAction {

  /// Navigate to a new path.
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - scene: The scene to navigate.
  ///   - isDetail: Applies to the detail route.
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func navigate(
    to path: String,
    inScene scene: String = SceneState.mainSceneName,
    isDetail: Bool = false,
    animate: Bool = true
  ) -> Action {
    NavigationAction.beginRouting(path: path, scene: scene, isDetail: isDetail, animate: animate)
  }
  
  /// Navigate to a new path with a URL.
  ///
  /// The URL represents the entire path to a scene's routes. The first path component must be the name of the scene.
  /// A fragment may be added to represent the detail route.
  ///
  /// `sceneName/path/to/route#/detail/route/`
  ///
  /// - Parameters:
  ///   - url: A URL to the new path.
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func navigate(
    to url: URL,
    animate: Bool = true
  ) -> Action {
    guard let sceneName = url.pathComponents.first else { return EmptyAction() }
    var routePath = url.pathComponents.dropFirst().joined(separator: "/")
    let detailRoutePath = url.fragment
    
    if routePath.isEmpty {
      routePath = "/"
    }
    
    return ActionPlan<NavigationStateRoot> { store in
      store.send(navigate(to: routePath, inScene: sceneName, animate: true))
      if let detailRoutePath = detailRoutePath {
        store.send(navigate(to: detailRoutePath, inScene: sceneName, isDetail: true, animate: true))
      }
    }
  }

  /// Navigate to an ancestor path.
  ///
  /// If the path is of a target route, it will perserve its active branch.
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - scene: The scene to navigate.
  ///   - isDetail: Applies to the detail route.
  ///   - preserveBranch: If the route has an active branch, preserve it
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func pop(
    to path: String,
    inScene scene: String = SceneState.mainSceneName,
    isDetail: Bool,
    preserveBranch: Bool = false,
    animate: Bool = true
  ) -> Action {
    NavigationAction.beginPop(path: path, scene: scene, isDetail: isDetail, preserveBranch: preserveBranch, animate: animate)
  }
}
