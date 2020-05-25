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

  private func beginRouting(route: inout NavigationState.Route, path: String, skipIfAncestor: Bool, animate: Bool) {
    let url = path.standardizedURL(withBasePath: route.path)
    guard let absolutePath = url?.absoluteString else { return }
    let resolvedPath = pathFromCache(route: route, path: absolutePath) ?? absolutePath
    guard !skipIfAncestor || !route.path.starts(with: resolvedPath) else { return }
    let (segments, orderedLegPaths) = buildRouteSegments(path: resolvedPath)
    route = NavigationState.Route(
      path: resolvedPath,
      legsByPath: segments,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      animate: animate && absolutePath == resolvedPath,
      completed: false
    )
    updateCache(route: &route)
  }

  private func buildRouteState(route: NavigationState.Route, absolutePath: String) -> NavigationState.Route {
    let resolvedPath = pathFromCache(route: route, path: absolutePath) ?? absolutePath
    let (segments, orderedLegPaths) = buildRouteSegments(path: resolvedPath)
    var nextRoute = NavigationState.Route(
      path: resolvedPath,
      legsByPath: segments,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      completed: false
    )
    updateCache(route: &nextRoute)
    return nextRoute
  }

  private func buildRouteSegments(path: String) -> ([String: NavigationState.RouteLeg], [String]) {
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

  private func completeRouting(route: inout NavigationState.Route) {
    route.animate = false
    route.completed = true
  }

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

  private func stopCaching(route: inout NavigationState.Route, path: String) {
    route.caches.removeValue(forKey: path)
  }

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

  private func pathFromCache(route: NavigationState.Route, path: String) -> String? {
    guard !route.path.starts(with: path) else { return path }
    let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
    let parentPath = components.dropLast().joined(separator: "/").standardizedPath() ?? "/"
    return components.last.flatMap { route.caches[parentPath]?.snapshots[$0] }
  }
}
