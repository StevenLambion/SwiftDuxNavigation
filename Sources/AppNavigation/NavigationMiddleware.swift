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

  /// Triggers when an error occurs with navigaiton.
  /// The default implementation redirects the route to the root waypoint if route completion fails.
  private var onError: ErrorHandler

  /// Initiate a new navigation middleware.
  ///
  /// - Parameters:
  ///   - onNavigate: A closure to filter and control navigation events.
  ///   - onError: A closure called when there's navigation errors.
  public init(
    onNavigate: NavigateHandler? = nil,
    onError: @escaping ErrorHandler = Self.defaultErrorHandler
  ) {
    self.onNavigate = onNavigate
    self.onError = onError
  }

  public func run(store: StoreProxy<State>, action: Action) -> Action? {
    switch action {
    case StoreAction<State>.reset:
      store.send(NavigationAction.verifyAllRouteCompeletions())
      return action
    case NavigationAction.setError(let error, let message):
      onError(store, error, message)
      return action
    case NavigationAction.beginRouting(let path, let routeName, let isDetail, _):
      return onNavigate?(store, path, routeName, isDetail) ?? true ? action : nil
    default:
      return action
    }
  }
}

extension NavigationMiddleware {

  /// Determine if a route is navigable by the user.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - path: The path of the route.
  ///   - routeName: The name of the route..
  ///   - isDetail: If it's the detail route..
  /// - Returns: True to allow the routing or false to stop it.
  public typealias NavigateHandler = (StoreProxy<State>, String, String, Bool) -> Bool

  /// Handle navigational errors, and provide ways to recover from them.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public typealias ErrorHandler = (StoreProxy<State>, Error, String) -> Void

  /// Default error handler. It redirect failed routes to the root path. It also prints any errors.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func defaultErrorHandler(store: StoreProxy<State>, error: Error, message: String) {
    routeCompletionFailedErrorHandler(store: store, error: error, message: message)
    printErrorHandler(store: store, error: error, message: message)
  }

  /// Use as an error handler to redirect failed routes to the root path.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func routeCompletionFailedErrorHandler(store: StoreProxy<State>, error: Error, message: String) {
    guard let error = error as? NavigationError else { return }

    if case .routeCompletionFailed(let routeName, let isDetail) = error {
      store.send(NavigationAction.navigate(to: "/", inRoute: routeName, isDetail: isDetail))
    }
  }

  /// Use as an error handler to print out the error messages.
  ///
  /// - Parameters:
  ///   - store: The store. It can be used to send actions within the handler.
  ///   - error: The navigational error.
  ///   - message:The error message, useful for logging.
  public static func printErrorHandler(store: StoreProxy<State>, error: Error, message: String) {
    print(message)
  }
}
