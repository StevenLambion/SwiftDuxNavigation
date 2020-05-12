import Foundation
import SwiftDux

/// Reduces the navigation state.
public struct NavigationReducer<State>: Reducer where State: NavigationStateRoot {

  public init() {}

  public func reduce(state: State, action: NavigationAction) -> State {
    var state = state

    switch action {
    case .beginRouting(let path, let sceneName, let animate):
      state = updateScene(named: sceneName, in: state) {
        $0.route = beginRouting(to: path, state: $0.route, animate: animate)
      }
    case .beginPop(let path, let sceneName, let animate):
      state = updateScene(named: sceneName, in: state) {
        $0.route = beginPop(to: path, state: $0.route, animate: animate)
      }
    case .completeRouting(let sceneName):
      state = updateScene(named: sceneName, in: state) {
        $0.route = completeRouting(state: $0.route)
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

  private func beginRouting(to path: String, state: RouteState, animate: Bool) -> RouteState {
    guard let resolvedPath = resolveAbsolutePath(path: path, previousPath: state.path) else {
      return state
    }
    let (segments, lastSegment) = buildRouteSegments(path: resolvedPath)
    return RouteState(
      path: resolvedPath,
      legsByPath: segments,
      lastLeg: lastSegment,
      animate: animate,
      completed: false
    )
  }

  private func completeRouting(state: RouteState) -> RouteState {
    var state = state
    state.completed = true
    return state
  }

  private func beginPop(to path: String, state: RouteState, animate: Bool) -> RouteState {
    guard let resolvedPath = resolveAbsolutePath(path: path, previousPath: state.path) else {
      return state
    }
    guard let segment = state.legsByPath[resolvedPath] else { return state }
    return beginRouting(to: segment.path, state: state, animate: animate)
  }

  private func resolveAbsolutePath(path: String, previousPath: String) -> String? {
    let path = path.last == "/" ? path : path + "/"
    guard !path.starts(with: "/") else { return path }
    return URL(string: "\(previousPath)/\(path)")?.standardized.absoluteString
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
