import Foundation
import SwiftDux
import SwiftUI

/// Navigation actions
public enum NavigationAction: Action {

  /// Remove a scene from state  by name.
  case clearScene(named: String)

  /// Begin routing to a new path.
  case beginRouting(path: String, scene: String, animate: Bool)

  /// Begin popping the navigation to an ancestor path.
  case beginPop(path: String, preserveBranch: Bool, scene: String, animate: Bool)

  /// Complete the navigation routing.
  case completeRouting(scene: String)
}

extension NavigationAction {

  /// Navigate to a new path.
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - scene: The scene to navigate.
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func navigate(
    to path: String,
    in scene: String = SceneState.mainSceneName,
    animate: Bool = true
  ) -> Action {
    NavigationAction.beginRouting(path: path, scene: scene, animate: animate)
  }

  /// Navigate to an ancestor path.
  ///
  /// If the path is of a target route, it will perserve its active branch.
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - scene: The scene to navigate.
  ///   - preserveBranch: If the route has an active branch, preserve it
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func pop(
    to path: String,
    in scene: String = SceneState.mainSceneName,
    preserveBranch: Bool = false,
    animate: Bool = true
  ) -> Action {
    NavigationAction.beginPop(path: path, preserveBranch: preserveBranch, scene: scene, animate: animate)
  }
}
