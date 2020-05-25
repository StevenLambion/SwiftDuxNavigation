import Combine
import Foundation
import SwiftDux
import SwiftUI

/// Observes the navigational state to provide additional functionality andto help
/// perserve the integrity of the navigation system.
public struct NavigationMiddleware<State>: Middleware where State: NavigationStateRoot {

  /// Triggers when completion failed. It provide the scene name and if it is the detail route.
  /// The default implementation redirects the route to the root waypoint.
  private var onCompletionFailed: (StoreProxy<State>, String, Bool) -> Void

  public init(
    onCompletionFailed: @escaping (StoreProxy<State>, String, Bool) -> Void = { store, scene, isDetail in
      store.send(NavigationAction.navigate(to: "/", isDetail: isDetail, animate: false))
    }
  ) {
    self.onCompletionFailed = onCompletionFailed
  }

  public func run(store: StoreProxy<State>, action: Action) {
    store.next(action)
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
    case NavigationAction.setError(let error, _):
      if case .routeCompletionFailed(let scene, let isDetail) = error {
        onCompletionFailed(store, scene, isDetail)
      }
    default:
      break
    }
  }
}
