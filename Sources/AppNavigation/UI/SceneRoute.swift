import SwiftDux
import SwiftUI

/// Starts a new Route for a SwiftUI Scene.
///
/// This view is meant to be placed at the root of a Scene and passed a store. It persists
/// its state through the scene's storage mechanism, so that it can automatically clean up when
/// the scene has been disconnected by the user.
public struct SceneRoute<StateType, Content>: View where StateType: Equatable & NavigationStateRoot, Content: View {
  @Environment(\.actionDispatcher) private var dispatch
  @Environment(\.scenePhase) private var scenePhase
  @SceneStorage("SceneRoute.routeStorage") private var routeStorageData: Data?

  public var store: Store<StateType>
  public var name = UUID().uuidString
  public var content: Content

  /// Initiate a Route placed within a Scene.
  ///
  /// - Parameters:
  ///   -  store: The store to be injected.
  ///   -  content: A closure that returns the content of the waypoint.
  public init(store: Store<StateType>, @ViewBuilder content: () -> Content) {
    self.store = store
    self.content = content()
  }

  public var body: some View {
    Route(name: name) { content }
      .provideStore(store)
      .onChange(of: scenePhase, perform: onScenePhaseChange)
  }

  private func onScenePhaseChange(scenePhase: ScenePhase) {
    switch scenePhase {
    case .active:
      restoreRoute()
    case .background:
      saveRoute()
    default:
      break
    }
  }

  private func restoreRoute() {
    guard let routeStorageData = routeStorageData,
      let routeStorage = try? JSONDecoder().decode(RouteStorage.self, from: routeStorageData)
    else { return }

    dispatch(NavigationAction.addRoute(primary: routeStorage.primaryRoute, detail: routeStorage.detailRoute))
  }

  private func saveRoute() {
    guard let primaryRoute = store.state.navigation.primaryRouteByName[name],
      let detailRoute = store.state.navigation.detailRouteByName[name]
    else { return }

    let routeStorage = RouteStorage(
      primaryRoute: primaryRoute,
      detailRoute: detailRoute
    )

    self.routeStorageData = try? JSONEncoder().encode(routeStorage)
    dispatch(NavigationAction.removeRoute(named: name))
  }
}

extension SceneRoute {
  private struct RouteStorage: Codable {
    var primaryRoute: NavigationState.RouteState
    var detailRoute: NavigationState.RouteState
  }
}

extension SceneRoute where StateType == SceneNavigationState {

  /// Initiate a SceneRoute.
  ///
  /// - Parameter content: The contents of the SceneRoute.
  public init(@ViewBuilder content: () -> Content) {
    self.init(
      store: Store(
        state: SceneNavigationState(),
        reducer: NavigationReducer(),
        middleware: NavigationMiddleware()
      ),
      content: content
    )
  }

  /// Initiate a SceneRoute.
  ///
  /// - Parameters:
  ///   - middleware: Extra middleware to provide to the internal navigation store.
  ///   - content: The contents of the SceneRoute.
  public init<M>(middleware: M, @ViewBuilder content: () -> Content) where M: Middleware, M.State == StateType {
    self.init(
      store: Store(
        state: SceneNavigationState(),
        reducer: NavigationReducer(),
        middleware: NavigationMiddleware() + middleware
      ),
      content: content
    )
  }
}

public struct SceneNavigationState: Equatable, Codable, NavigationStateRoot {
  public var navigation: NavigationState = NavigationState()
}
