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
    let url = isDetail ? path.standardizedURL(withBasePath: route.path) : nil
    if let absolutePath = url?.absoluteString {
      let route = buildRouteState(state: route, absolutePath: absolutePath)
      if isDetail {
        state.detailRoute = route
      } else {
        state.route = route
      }
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
}
