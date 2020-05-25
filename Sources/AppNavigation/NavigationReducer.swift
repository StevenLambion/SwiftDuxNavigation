import Foundation
import SwiftDux

/// Reduces the navigation state.
public struct NavigationReducer<State>: Reducer where State: NavigationStateRoot {

  public init() {}

  public func reduce(state: State, action: NavigationAction) -> State {
    var state = state

    switch action {
    case .setOptions(let options):
      state.navigation.options = options
    case .setError(let error, let message):
      state.navigation.lastNavigationError = error
      state.navigation.lastNavigationErrorMessage = message
    case .beginRouting(let path, let sceneName, let isDetail, let skipIfAncestor, let animate):
      state = updateRoute(in: state, forScene: sceneName, isDetail: isDetail) { route, scene in
        beginRouting(route: &route, path: path, skipIfAncestor: skipIfAncestor, animate: animate)
      }
    case .completeRouting(let sceneName, let isDetail):
      state = updateRoute(in: state, forScene: sceneName, isDetail: isDetail) { route, scene in
        completeRouting(route: &route)
      }
    case .clearScene(let name):
      state.navigation.sceneByName.removeValue(forKey: name)
    case .beginCaching(let path, let sceneName, let isDetail, let policy):
      state = updateRoute(in: state, forScene: sceneName, isDetail: isDetail) { route, scene in
        beginCaching(route: &route, path: path, policy: policy)
      }
    case .stopCaching(let path, let sceneName, let isDetail):
      state = updateRoute(in: state, forScene: sceneName, isDetail: isDetail) { route, scene in
        stopCaching(route: &route, path: path)
      }
    }
    return state
  }

  private func updateScene(in state: State, named name: String, updater: (inout NavigationState.Scene) -> Void)
    -> State
  {
    var state = state
    var scene = state.navigation.sceneByName[name] ?? NavigationState.Scene(name: name)
    updater(&scene)
    state.navigation.sceneByName[name] = scene
    if !state.navigation.options.animationEnabled {
      scene.route.animate = false
      scene.detailRoute.animate = false
    }
    return state
  }

  private func updateRoute(
    in state: State,
    forScene sceneName: String,
    isDetail: Bool,
    updater: (inout NavigationState.Route, inout NavigationState.Scene) -> Void
  )
    -> State
  {
    updateScene(in: state, named: sceneName) { scene in
      var route = isDetail ? scene.detailRoute : scene.route
      updater(&route, &scene)
      if isDetail {
        scene.detailRoute = route
      } else {
        scene.route = route
      }
    }
  }

  /// Begin the routing state.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The new path.
  ///   - skipIfAncestor: If it should skip ancestor paths.
  ///   - animate: Animate the routing.
  private func beginRouting(route: inout NavigationState.Route, path: String, skipIfAncestor: Bool, animate: Bool) {
    let url = path.standardizedURL(withBasePath: route.path)
    guard let absolutePath = url?.absoluteString else { return }
    let resolvedPath = pathFromCache(route: route, path: absolutePath) ?? absolutePath
    guard !skipIfAncestor || !route.path.starts(with: resolvedPath) else { return }
    let (legs, orderedLegPaths) = buildRouteLegs(path: resolvedPath)
    route = NavigationState.Route(
      path: resolvedPath,
      legsByPath: legs,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      animate: animate && absolutePath == resolvedPath,
      completed: false
    )
    updateCache(route: &route)
  }

  /// Build the legs of a route.
  ///
  /// - Parameter path: The route path.
  /// - Returns: The next legs.
  private func buildRouteLegs(path: String) -> ([String: NavigationState.RouteLeg], [String]) {
    let pathComponents = path.split(separator: "/", omittingEmptySubsequences: false)
    var legs = [String: NavigationState.RouteLeg](minimumCapacity: pathComponents.count)
    var orderedLegPaths = [String]()
    var nextLeg = NavigationState.RouteLeg()
    for component in pathComponents.dropFirst().dropLast() {
      nextLeg = nextLeg.append(component: String(component))
      legs[nextLeg.parentPath] = nextLeg
      orderedLegPaths.append(nextLeg.parentPath)
    }
    orderedLegPaths.append(nextLeg.path)
    return (legs, orderedLegPaths)
  }

  /// Completes the routing state.
  ///
  /// - Parameter route: The route to complete.
  private func completeRouting(route: inout NavigationState.Route) {
    route.animate = false
    route.completed = true
  }

  /// Begin caching child routes for a   path.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The route path that will cache its children.
  ///   - policy: The caching policy.
  private func beginCaching(route: inout NavigationState.Route, path: String, policy: NavigationState.RouteCachingPolicy) {
    guard route.caches[path] == nil else { return }
    guard let pathIndex = route.orderedLegPaths.lastIndex(of: path) else { return }
    let parentPath = route.orderedLegPaths[max(pathIndex - 1, 0)]
    route.caches[path] = NavigationState.RouteCache(
      policy: policy,
      parentPath: parentPath,
      path: path
    )
  }

  /// Stop caching child routes for a path.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The  path.
  private func stopCaching(route: inout NavigationState.Route, path: String) {
    route.caches.removeValue(forKey: path)
  }

  /// Updates the route state's cache.
  ///
  /// It adds a new entry to the cache if the current route state has a matching path. It
  /// then removes existing entries who's caching policy has expired.
  /// - Parameter route: The current route state.
  private func updateCache(route: inout NavigationState.Route) {
    var caches = route.caches
    if let cachePath = route.orderedLegPaths.last(where: { caches[$0] != nil }) {
      if let component = route.legsByPath[cachePath]?.component {
        caches[cachePath]?.snapshots[component] = route.path
      }
    }

    route.caches = caches.filter { key, cache in
      switch cache.policy {
      case .whileActive:
        return route.path == cache.path || route.legsByPath[cache.path] != nil
      case .whileParentActive:
        return route.path == cache.parentPath || route.legsByPath[cache.parentPath] != nil
      default:
        return true
      }
    }
  }

  /// Resolve a route path from the cache if it exists.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The route path to resolve from.
  /// - Returns: The cached path if found.
  private func pathFromCache(route: NavigationState.Route, path: String) -> String? {
    guard !route.path.starts(with: path) else { return path }
    let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
    let parentPath = components.dropLast().joined(separator: "/").standardizedPath() ?? "/"
    return components.last.flatMap { route.caches[parentPath]?.snapshots[$0] }
  }
}
