import Foundation
import SwiftDux

/// Reduces the navigation state.
public struct NavigationReducer<State>: Reducer where State: NavigationStateRoot {

  public init() {}

  public func reduce(state: State, action: NavigationAction) -> State {
    var state = state

    switch action {
    case .beginRouting(let path, let sceneName, let isDetail, let animate):
      state = updateRoute(forScene: sceneName, isDetail: isDetail, in: state) { route, scene in
        scene.animate = animate
        scene.animate = beginRouting(route: &route, path: path)
      }
    case .beginPop(let path, let sceneName, let isDetail, let perserveBranch, let animate):
      state = updateRoute(forScene: sceneName, isDetail: isDetail, in: state) { route, scene in
        scene.animate = animate
        scene.animate = beginPop(route: &route, path: path, perserveBranch: perserveBranch)
      }
    case .completeRouting(let sceneName, let isDetail):
      state = updateRoute(forScene: sceneName, isDetail: isDetail, in: state) { route, scene in
        scene.animate = false
        completeRouting(route: &route)
      }
    case .clearScene(let name):
      state.navigation.sceneByName.removeValue(forKey: name)
    case .beginCaching(let path, let sceneName, let isDetail, let policy):
      state = updateRoute(forScene: sceneName, isDetail: isDetail, in: state) { route, scene in
        beginCaching(route: &route, path: path, policy: policy)
      }
    case .stopCaching(let path, let sceneName, let isDetail):
      state = updateRoute(forScene: sceneName, isDetail: isDetail, in: state) { route, scene in
        stopCaching(route: &route, path: path)
      }
    }
    return state
  }

  private func updateScene(named name: String, in state: State, updater: (inout SceneState) -> Void)
    -> State
  {
    var state = state
    var scene = state.navigation.sceneByName[name] ?? SceneState(name: name)
    updater(&scene)
    state.navigation.sceneByName[name] = scene
    return state
  }

  private func updateRoute(forScene sceneName: String, isDetail: Bool, in state: State, updater: (inout RouteState, inout SceneState) -> Void)
    -> State
  {
    updateScene(named: sceneName, in: state) { scene in
      var route = isDetail ? scene.detailRoute : scene.route
      updater(&route, &scene)
      if isDetail {
        scene.detailRoute = route
      } else {
        scene.route = route
      }
    }
  }

  private func beginRouting(route: inout RouteState, path: String) -> Bool {
    let url = path.standardizedURL(withBasePath: route.path)
    guard let absolutePath = url?.absoluteString else { return false }
    let resolvedPath = pathFromCache(route: route, path: absolutePath) ?? absolutePath
    let (segments, orderedLegPaths) = buildRouteSegments(path: resolvedPath)
    route = RouteState(
      path: resolvedPath,
      legsByPath: segments,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      completed: false
    )
    updateCache(route: &route)
    return absolutePath == resolvedPath
  }

  private func buildRouteState(route: RouteState, absolutePath: String) -> RouteState {
    let resolvedPath = pathFromCache(route: route, path: absolutePath) ?? absolutePath
    let (segments, orderedLegPaths) = buildRouteSegments(path: resolvedPath)
    var nextRoute = RouteState(
      path: resolvedPath,
      legsByPath: segments,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      completed: false
    )
    updateCache(route: &nextRoute)
    return nextRoute
  }

  private func buildRouteSegments(path: String) -> ([String: RouteLeg], [String]) {
    let pathComponents = path.split(separator: "/", omittingEmptySubsequences: false)
    var legs = [String: RouteLeg](minimumCapacity: pathComponents.count)
    var orderedLegPaths = [String]()
    var nextLeg = RouteLeg()
    for component in pathComponents.dropFirst().dropLast() {
      nextLeg = nextLeg.append(component: String(component))
      legs[nextLeg.parentPath] = nextLeg
      orderedLegPaths.append(nextLeg.parentPath)
    }
    orderedLegPaths.append(nextLeg.path)
    return (legs, orderedLegPaths)
  }

  private func completeRouting(route: inout RouteState) {
    route.completed = true
  }

  private func beginPop(route: inout RouteState, path: String, perserveBranch: Bool) -> Bool {
    guard let resolvedPath = path.standardizedPath(withBasePath: route.path) else {
      return false
    }
    guard let segment = route.legsByPath[resolvedPath] else { return false }
    return beginRouting(route: &route, path: perserveBranch ? segment.path : segment.parentPath)
  }

  private func beginCaching(route: inout RouteState, path: String, policy: RouteCachingPolicy) {
    guard route.caches[path] == nil else { return }
    guard let pathIndex = route.orderedLegPaths.lastIndex(of: path) else { return }
    let parentPath = route.orderedLegPaths[max(pathIndex - 1, 0)]
    route.caches[path] = RouteCache(
      policy: policy,
      parentPath: parentPath,
      path: path
    )
  }

  private func stopCaching(route: inout RouteState, path: String) {
    route.caches.removeValue(forKey: path)
  }

  private func updateCache(route: inout RouteState) {
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

  private func pathFromCache(route: RouteState, path: String) -> String? {
    guard !route.path.starts(with: path) else { return path }
    let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
    let parentPath = components.dropLast().joined(separator: "/").standardizedPath() ?? "/"
    return components.last.flatMap { route.caches[parentPath]?.snapshots[$0] }
  }
}
