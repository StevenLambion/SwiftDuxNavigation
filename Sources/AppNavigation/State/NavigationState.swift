import Foundation
import SwiftDux

/// Integrates the navigation into the application state.
public protocol NavigationStateRoot {
  var navigation: NavigationState { get set }
}

/// The state of the navigation system.
public struct NavigationState: StateType {

  /// All scenes by their name.
  public var sceneByName: [String: Scene] = [
    Scene.defaultName: Scene(name: Scene.defaultName)
  ]

  public init(
    sceneByName: [String: Scene] = [
      Scene.defaultName: Scene(name: Scene.defaultName)
    ]
  ) {
    self.sceneByName = sceneByName
  }
}
