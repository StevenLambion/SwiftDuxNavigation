import Foundation
import SwiftDux

/// Reduces the navigation state.
public struct NavigationReducer<State>: Reducer where State: NavigationStateRoot {

  public init() {}

  public func reduce(state: State, action: NavigationAction) -> State {
    var state = state

    switch action {
    case .beginRouting(let path, let sceneName, let isDetail, let animate):
      state = updateScene(named: sceneName, in: state) {
        $0.animate = animate
        beginRouting(state: &$0, path: path, isDetail: isDetail)
      }
    case .beginPop(let path, let sceneName, let isDetail, let perserveBranch, let animate):
      state = updateScene(named: sceneName, in: state) {
        $0.animate = animate
        beginPop(state: &$0, path: path, perserveBranch: perserveBranch, isDetail: isDetail)
      }
    case .completeRouting(let sceneName, let isDetail):
      state = updateScene(named: sceneName, in: state) {
        $0.animate = false
        completeRouting(state: &$0, isDetail: isDetail)
      }
    case .clearScene(let name):
      state.navigation.sceneByName.removeValue(forKey: name)
    case .setSnapshot(let path, let sceneName, let isDetail, let forDetail, let identifier):
      state = updateScene(named: sceneName, in: state) {
        snapshotRoute(state: &$0, path: path, isDetail: isDetail, forDetail: forDetail, identifier: identifier)
      }
    case .restoreSnapshot(let path, let sceneName, let isDetail, let identifier):
      state = updateScene(named: sceneName, in: state) {
        restoreSnapshot(state: &$0, path: path, isDetail: isDetail, identifier: identifier)
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

  private func beginRouting(state: inout SceneState, path: String, isDetail: Bool) {
    let route = isDetail ? state.detailRoute : state.route
    let url = path.standardizedURL(withBasePath: route.path)
    if let absolutePath = url?.absoluteString {
      let route = buildRouteState(state: route, absolutePath: absolutePath)
      if isDetail {
        state.detailRoute = route
      } else {
        state.route = route
      }
      pruneSnapshots(state: &state)
    }
  }

  private func buildRouteState(state: RouteState, absolutePath: String) -> RouteState {
    let (segments, lastSegment) = buildRouteSegments(path: absolutePath)
    return RouteState(
      path: absolutePath,
      legsByPath: segments,
      lastLeg: lastSegment,
      completed: false
    )
  }

  private func completeRouting(state: inout SceneState, isDetail: Bool) {
    if isDetail {
      state.detailRoute.completed = true
    } else {
      state.route.completed = true
    }
  }

  private func beginPop(state: inout SceneState, path: String, perserveBranch: Bool, isDetail: Bool) {
    let route = isDetail ? state.detailRoute : state.route
    guard let resolvedPath = path.standardizedPath(withBasePath: !isDetail ? state.route.path : state.detailRoute.path) else {
      return
    }
    guard let segment = route.legsByPath[resolvedPath] else { return }
    beginRouting(state: &state, path: perserveBranch ? segment.path : segment.parentPath, isDetail: isDetail)
  }

  private func buildRouteSegments(path: String) -> ([String: RouteLeg], RouteLeg) {
    let pathComponents = path.split(separator: "/", omittingEmptySubsequences: false)
    var segments = [String: RouteLeg](minimumCapacity: pathComponents.count)
    let lastSegment = pathComponents.dropFirst().dropLast().reduce(RouteLeg()) {
      previousSegment,
      component in
      let segment = previousSegment.append(component: String(component))
      segments[segment.parentPath] = segment
      return segment
    }
    return (segments, lastSegment)
  }

  private func snapshotRoute(state: inout SceneState, path: String, isDetail: Bool, forDetail: Bool, identifier: String) {
    let pathToSnapshot = forDetail ? state.detailRoute.path : state.route.path
    let bucketKey = state.snapshotKey(forPath: path, isDetail: isDetail)
    var bucket = state.snapshots[bucketKey] ?? [:]
    bucket[identifier] = RouteSnapshot(id: identifier, path: pathToSnapshot, isDetail: forDetail)
    state.snapshots[path] = bucket
  }

  private func restoreSnapshot(state: inout SceneState, path: String, isDetail: Bool, identifier: String) {
    let bucketKey = state.snapshotKey(forPath: path, isDetail: isDetail)
    guard let snapshot = state.snapshots[bucketKey]?[identifier] else { return }
    state.animate = false
    beginRouting(state: &state, path: snapshot.path, isDetail: snapshot.isDetail)
  }

  private func pruneSnapshots(state: inout SceneState) {
    state.snapshots = state.snapshots.filter { key, value in
      let isDetail = key.starts(with: "#")
      let path = isDetail ? String(key.dropFirst()) : key
      let route = isDetail ? state.detailRoute : state.route
      return route.path == path || route.legsByPath[path] != nil
    }
  }
}
