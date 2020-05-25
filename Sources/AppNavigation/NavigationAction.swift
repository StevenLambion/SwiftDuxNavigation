import Combine
import Foundation
import SwiftDux
import SwiftUI

/// Navigation actions
public enum NavigationAction: Action {
  /// Set an error object.
  case setOptions(NavigationState.Options)

  /// Set an error object.
  case setError(NavigationError, message: String)

  /// Remove a scene from state  by name.
  case clearScene(String)

  /// Begin routing to a new path.
  case beginRouting(path: String, scene: String, isDetail: Bool, animate: Bool)

  /// Complete the navigation routing.
  case completeRouting(scene: String, isDetail: Bool)

  /// Begin caching a route's children.
  case beginCaching(path: String, scene: String, isDetail: Bool, policy: NavigationState.RouteCachingPolicy)

  /// Stops caching a route's children.
  case stopCaching(path: String, scene: String, isDetail: Bool)
}

extension NavigationAction {

  /// Navigate to a new path.
  /// 
  /// - Parameters:
  ///   - path: The path to navigate to. It can be an absolute or relative path.
  ///   - scene: The scene to navigate.
  ///   - isDetail: Applies to the detail route.
  ///   - animate: Animate the navigational transition.
  /// - Returns: The navigation action.
  public static func navigate(
    to path: String,
    inScene scene: String = NavigationState.Scene.defaultName,
    isDetail: Bool = false,
    animate: Bool = true
  ) -> ActionPlan<NavigationStateRoot> {
    ActionPlan { store, completed in
      let getRoute = self.routeGetter(forScene: scene, isDetail: isDetail)
      guard let route = getRoute(store) else {
        completed()
        return nil
      }
      if !route.completed {
        store.send(self.completeRouting(scene: scene, isDetail: isDetail))
      }
      store.send(
        NavigationAction.beginRouting(
          path: path,
          scene: scene,
          isDetail: isDetail,
          animate: animate
        )
      )
      return waitForRouteCompeletion(forStore: store, inScene: scene, isDetail: isDetail, completed: completed)
    }
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

  /// A getter that retrieves a specific route from a scene.
  ///
  /// - Parameters:
  ///   - sceneName: The scene containing the route.
  ///   - isDetail: If it should get the detail route.
  /// - Returns: The getter.
  private static func routeGetter(forScene sceneName: String, isDetail: Bool) -> (StoreProxy<NavigationStateRoot>) -> NavigationState.Route? {
    let getScene = sceneGetter(forScene: sceneName)
    return { store in
      guard let scene = getScene(store) else { return nil }
      return isDetail ? scene.detailRoute : scene.route
    }
  }

  /// A getter that retrieves a specific scene.
  ///
  /// - Parameter sceneName: The name of the scene.
  /// - Returns: The getter.
  private static func sceneGetter(forScene sceneName: String) -> (StoreProxy<NavigationStateRoot>) -> NavigationState.Scene? {
    { store in
      guard let scene = store.state.navigation.sceneByName[sceneName] else {
        store.send(self.setError(.sceneNotFound, message: "Scene not found for: '\(sceneName)'"))
        return nil
      }
      return scene
    }
  }

  /// Creates a subscription that completes once an active route has finished resolving.
  ///
  /// If a route isn't completed in a given time range, it will timeout.
  /// - Parameters:
  ///   - store: The store.
  ///   - sceneName: The route's scene.
  ///   - isDetail: If it is the detail route.
  ///   - completed: Called once the route is completed.
  /// - Returns: The AnyCancellable.
  private static func waitForRouteCompeletion(
    forStore store: StoreProxy<NavigationStateRoot>,
    inScene sceneName: String,
    isDetail: Bool,
    completed: @escaping () -> Void
  )
    -> AnyCancellable
  {
    let getRoute = routeGetter(forScene: sceneName, isDetail: isDetail)
    let options = store.state.navigation.options
    return store.didChange
      .setFailureType(to: NavigationError.self)
      .timeout(options.completionTimeout, scheduler: RunLoop.main) { NavigationError.routeCompletionFailed }
      .compactMap { _ in getRoute(store) }
      .filter { $0.completed }
      .first { _ in true }
      .sink(
        receiveCompletion: { completion in
          defer { completed() }
          if case .failure(let error) = completion {
            store.send(self.setError(error, message: "Route completion timed out for: '\(getRoute(store)?.path ?? "")'"))
            store.send(NavigationAction.completeRouting(scene: sceneName, isDetail: isDetail))
          }
        },
        receiveValue: { _ in }
      )
  }
}
