import Foundation
import SwiftDux

/// Integrates the navigation into the application state.
public protocol NavigationStateRoot {
  var navigation: NavigationState { get set }
}

/// The state of the navigation system.
public struct NavigationState: StateType {
  /// Options of the navigation state.
  public var options: Options = Options()

  /// All scenes by their name.
  public var sceneByName: [String: Scene]

  public var lastNavigationError: NavigationError? = nil
  public var lastNavigationErrorMessage: String? = nil

  public init(
    options: Options = Options(),
    sceneByName: [String: Scene] = [
      Scene.defaultName: Scene(name: Scene.defaultName)
    ],
    lastNavigationError: NavigationError? = nil,
    lastNavigationErrorMessage: String? = nil
  ) {
    self.options = options
    self.sceneByName = sceneByName
    self.lastNavigationError = lastNavigationError
    self.lastNavigationErrorMessage = lastNavigationErrorMessage
  }

  public enum CodingKeys: String, CodingKey {
    case options, sceneByName
  }
}

extension NavigationState {

  /// Options for the NavigationState.
  public struct Options: StateType {

    /// The timeout for uncompleted routes.
    var completionTimeout: RunLoop.SchedulerTimeType.Stride

    /// Enable route animations.
    var animationEnabled: Bool

    public init(completionTimeout: RunLoop.SchedulerTimeType.Stride = .seconds(1), animationEnabled: Bool = true) {
      self.completionTimeout = completionTimeout
      self.animationEnabled = animationEnabled
    }
  }
}
