import Combine
import Foundation
import SwiftDux
import SwiftUI

/// Observes the navigational state to provide additional functionality andto help
/// perserve the integrity of the navigation system.
public struct NavigationMiddleware<State>: Middleware where State: NavigationStateRoot {

  /// Optional handler that controls the routes the user has access to. It can also be used
  /// to rediret the user to different route if needed. For example, they could be redirected
  /// to a login screen.
  private var onNavigate: NavigateHandler?

  /// Triggers when completion failed. It provide the scene name and if it is the detail route.
  /// The default implementation redirects the route to the root waypoint.
  private var onError: ErrorHandler

  public init(
    onNavigate: NavigateHandler? = nil,
    onError: @escaping ErrorHandler = Self.defaultErrorHandler
  ) {
    self.onNavigate = onNavigate
    self.onError = onError
  }

  public func run(store: StoreProxy<State>, action: Action) {
    if allowNavigationAction(store: store, action: action) {
      store.next(action)
      postActionRun(store: store, action: action)
    }
  }

  private func allowNavigationAction(store: StoreProxy<State>, action: Action) -> Bool {
    guard
      let onNavigate = onNavigate,
      case NavigationAction.beginRouting(let path, let scene, let isDetail, _, let animate) = action
    else { return true }
    return onNavigate(store, path, scene, isDetail, animate)
  }

  private func postActionRun(store: StoreProxy<State>, action: Action) {
    switch action {
    case NavigationAction.beginRouting(_, let scene, let isDetail, _, _):
      store.send(NavigationAction.verifyRouteCompeletion(inScene: scene, isDetail: isDetail))
    case StoreAction<State>.reset:
      store.state.navigation.sceneByName.forEach { sceneName, scene in
        if scene.route.path != "/" {
          store.send(NavigationAction.verifyRouteCompeletion(inScene: sceneName, isDetail: false))
        }
        if scene.detailRoute.path != "/" {
          store.send(NavigationAction.verifyRouteCompeletion(inScene: sceneName, isDetail: true))
        }
      }
    case NavigationAction.setError(let error, let message):
      onError(store, error, message)
    default:
      break
    }
  }
}

extension NavigationMiddleware {

  /// Determine if a route is navigable by the user.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - path: The path of the route.
  ///   - scene: The scene of the route..
  ///   - isDetail: If it's the detail route..
  ///   - animate: if the routing will animate.
  /// - Returns: True to allow the routing or false to stop it.
  public typealias NavigateHandler = (StoreProxy<State>, String, String, Bool, Bool) -> Bool

  /// Handle navigational errors, and provide ways to recover from them.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public typealias ErrorHandler = (StoreProxy<State>, NavigationError, String) -> Void

  /// Default error handler. It redirect failed routes to the root path. It also prints any errors.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func defaultErrorHandler(store: StoreProxy<State>, error: NavigationError, message: String) {
    routeCompletionFailedErrorHandler(store: store, error: error, message: message)
    printErrorHandler(store: store, error: error, message: message)
  }

  /// Use as an error handler to redirect failed routes to the root path.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func routeCompletionFailedErrorHandler(store: StoreProxy<State>, error: NavigationError, message: String) {
    if case .routeCompletionFailed(let scene, let isDetail) = error {
      store.send(NavigationAction.navigate(to: "/", inScene: scene, isDetail: isDetail, animate: false))
    }
  }

  /// Use as an error handler to print out the error messages.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func printErrorHandler(store: StoreProxy<State>, error: NavigationError, message: String) {
    print(message)
  }
}
