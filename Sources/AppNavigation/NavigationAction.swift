import Combine
import Foundation
import SwiftDux
import SwiftUI

/// Navigation actions
public enum NavigationAction: Action {

  /// Set an error object.
  case setOptions(NavigationState.Options)

  /// Set an error object.
  case setError(Error, message: String)

  /// Add a route to the navigation state.
  case addRoute(primary: NavigationState.RouteState?, detail: NavigationState.RouteState?)

  /// Remove a route from the navigation state.
  case removeRoute(routeName: String, isDetail: Bool)

  /// Begin routing to a new path.
  case setRoutePath(path: String, routeName: String, isDetail: Bool, skipIfAncestor: Bool)

  /// Completes the routing by verifying the provided paths match the route.
  case verifyRoutePaths(primaryPath: String, detailPath: String, routeName: String)

  /// Begin caching a route's children.
  case beginCaching(path: String, routeName: String, isDetail: Bool, policy: NavigationState.RouteCachingPolicy)

  /// Stops caching a route's children.
  case stopCaching(path: String, routeName: String, isDetail: Bool)
}

extension NavigationAction {

  /// Navigate to a new path.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - routeName: The name of the route to change.
  ///   - isDetail: Applies to the detail route.
  ///   - skipIfAncestor: Prevents the route from changing if the next path is an ancestor.
  ///   - verify: Verify that the route completes successfully.
  /// - Returns: The navigation action.
  public static func navigate(
    to path: String,
    inRoute routeName: String,
    isDetail: Bool = false,
    skipIfAncestor: Bool = false,
    verify: Bool = true
  ) -> Action {
    let action = setRoutePath(path: path, routeName: routeName, isDetail: isDetail, skipIfAncestor: skipIfAncestor)

    if verify {
      return action + verifyRouteCompeletion(inRoute: routeName, isDetail: isDetail)
    }

    return action
  }

  /// Navigate to a new path.
  ///
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - routeName: The name of the route to change.
  ///   - isDetail: Applies to the detail route.
  ///   - skipIfAncestor: Prevents the route from changing if the next path is an ancestor.
  ///   - isActive: Toggles the active state of the path.
  /// - Returns: The navigation action.
  public static func toggle(
    path: String,
    inRoute routeName: String,
    isDetail: Bool = false,
    skipIfAncestor: Bool = false,
    isActive: Bool
  ) -> Action {
    ActionPlan<NavigationStateRoot> { store in
      publishRoute(in: store.state.navigation, inRoute: routeName, isDetail: isDetail)
        .compactMap { route -> Action? in
          guard isActive || path == route.path else { return nil }
          return navigate(to: isActive ? path : "..", inRoute: routeName, isDetail: isDetail, skipIfAncestor: skipIfAncestor)
        }
        .catch { error -> Just<Action> in
          Just(setError(error, message: "Error when toggling route."))
        }
    }
  }

  /// Navigate to a new path with a URL.
  ///
  /// The URL represents the entire path of a route. The first path component must be the name of the route.
  /// A fragment may be added to represent the detail route.
  ///
  /// `routeName/path/to/route/#/detail/route/`
  ///
  /// - Parameter url: A URL to the new path.
  /// - Returns: The navigation action.
  public static func navigate(to url: URL) -> Action {
    ActionPlan<NavigationStateRoot> { store in
      guard let routeName = url.pathComponents.first else { return }
      var primaryPath = url.pathComponents.dropFirst().joined(separator: "/")
      let detailPath = url.fragment

      if primaryPath.isEmpty {
        primaryPath = "/"
      }

      store.send(navigate(to: primaryPath, inRoute: routeName))

      if let detailPath = detailPath {
        store.send(navigate(to: detailPath, inRoute: routeName, isDetail: true))
      }
    }
  }

  /// Verify that a route has completed.
  ///
  /// If a route isn't completed in a given time range, it will timeout.
  /// - Parameters:
  ///   - routeName: The route's name.
  ///   - isDetail: If it is the detail route.
  /// - Returns: The AnyCancellable.
  static func verifyRouteCompeletion(inRoute routeName: String, isDetail: Bool) -> Action {
    ActionPlan<NavigationStateRoot> { store in
      publishRoute(in: store.state.navigation, inRoute: routeName, isDetail: isDetail)
        .map { $0.path }
        .flatMap { routePath in
          store.publish { state in
            let navigation = state.navigation
            let route = isDetail ? navigation.detailRouteByName[routeName] : state.navigation.primaryRouteByName[routeName]
            return routePath != route?.path ?? "" || route?.completed ?? false
          }
        }
        .setFailureType(to: Error.self)
        .timeout(store.state.navigation.options.completionTimeout, scheduler: RunLoop.main) {
          NavigationError.routeCompletionFailed(route: routeName, isDetail: isDetail)
        }
        .filter { $0 }
        .first()
        .compactMap { _ in nil }
        .catch { (error: Error) -> Just<Action> in
          var errorAction: Action

          switch error as? NavigationError {
          case .routeCompletionFailed(_, _):
            errorAction = NavigationAction.setError(error, message: "Route completion timed out for the '\(routeName)' route.")
          default:
            errorAction = NavigationAction.setError(error, message: "Unknown error during route completion verification.")
          }

          return Just(errorAction)
        }
    }
  }

  /// Verify all routes have completed.
  ///
  /// If a route isn't completed in a given time range, it will timeout.
  /// - Returns: The AnyCancellable.
  static func removeInvalidRoutes() -> Action {
    ActionPlan<NavigationStateRoot> { store in
      store.publish { $0.navigation }
        .debounce(for: .seconds(5), scheduler: RunLoop.main)
        .first()
        .flatMap { navigation -> Publishers.Sequence<[Action], Never> in
          let validator = { (route: NavigationState.RouteState, isDetail: Bool) -> Action? in
            guard !route.completed else { return nil }
            return removeRoute(routeName: route.name, isDetail: isDetail)
          }

          var actions: [Action] = []

          actions += navigation.primaryRouteByName.values.compactMap { route in
            validator(route, false)
          }

          actions += navigation.detailRouteByName.values.compactMap { route in
            validator(route, true)
          }

          return actions.publisher
        }
    }
  }

  private static func publishRoute(in state: NavigationState, inRoute routeName: String, isDetail: Bool) -> AnyPublisher<NavigationState.RouteState, Never> {
    Just(state)
      .compactMap { state -> NavigationState.RouteState? in
        isDetail ? state.detailRouteByName[routeName] : state.primaryRouteByName[routeName]
      }
      .eraseToAnyPublisher()
  }
}
