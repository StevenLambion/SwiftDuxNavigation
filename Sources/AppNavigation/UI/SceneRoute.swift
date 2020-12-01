import SwiftDux
import SwiftUI

fileprivate var sceneStore = Store(
  state: SceneNavigationState(),
  reducer: NavigationReducer(),
  middleware: NavigationMiddleware()
)

/// Starts a new Route for a SwiftUI Scene.
///
/// This view is meant to be placed at the root of a Scene and passed a store. It persists
/// its state through the scene's storage mechanism, so that it can automatically clean up when
/// the scene has been disconnected by the user.
public struct SceneRoute<StateType, Content>: View where StateType: Equatable & NavigationStateRoot, Content: View {
  @Environment(\.actionDispatcher) private var dispatch
  @Environment(\.scenePhase) private var scenePhase
  @SceneStorage("SceneRoute.routeStorage") private var routeStorageData = Data()

  public var name: String
  public var store: Store<StateType>
  public var content: Content

  /// Initiate a Route placed within a Scene.
  ///
  /// - Parameters:
  ///   - name: An optional name of the route.
  ///   -  store: The store to be injected.
  ///   -  content: A closure that returns the content of the waypoint.
  public init(name: String? = nil, store: Store<StateType>, @ViewBuilder content: () -> Content) {
    self.name = name ?? UUID().uuidString
    self.store = store
    self.content = content()
  }

  public var body: some View {
    Route(name: name) { content }
      .provideStore(store)
      .onChange(of: scenePhase, perform: onScenePhaseChange)
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification, object: nil)) { _ in
        saveRoute()
      }
      .onAppear(perform: restoreRoute)
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
    guard let routeStorage = try? JSONDecoder().decode(RouteStorage.self, from: routeStorageData)
    else { return }

    var primary: NavigationState.RouteState? = nil
    var detail: NavigationState.RouteState? = nil

    if store.state.navigation.primaryRouteByName[name] == nil {
      primary = routeStorage.primaryRoute
    }

    if store.state.navigation.detailRouteByName[name] == nil {
      detail = routeStorage.detailRoute
    }

    dispatch(NavigationAction.addRoute(primary: primary, detail: detail))
  }

  private func saveRoute() {
    let routeStorage = RouteStorage(
      primaryRoute: store.state.navigation.primaryRouteByName[name] ?? NavigationState.RouteState(name: name),
      detailRoute: store.state.navigation.detailRouteByName[name] ?? NavigationState.RouteState(name: name)
    )

    self.$routeStorageData.wrappedValue = try! JSONEncoder().encode(routeStorage)

    dispatch(
      NavigationAction.removeRoute(named: name, isDetail: false) + NavigationAction.removeRoute(named: name, isDetail: true)
    )
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
      store: sceneStore,
      content: content
    )
  }
}

public struct SceneNavigationState: Equatable, Codable, NavigationStateRoot {
  public var navigation: NavigationState = NavigationState()
}
