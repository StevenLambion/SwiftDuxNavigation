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
      state.navigation.lastNavigationError = error as? NavigationError
      state.navigation.lastNavigationErrorMessage = message
    case .beginRouting(let path, let routeName, let isDetail, let skipIfAncestor):
      state = updateRoute(in: state, named: routeName, isDetail: isDetail) { route in
        beginRouting(for: &route, withPath: path, skipIfAncestor: skipIfAncestor)
      }
    case .completeRouting(let routeName, let isDetail):
      state = updateRoute(in: state, named: routeName, isDetail: isDetail) { route in
        completeRouting(route: &route)
      }
    case .addRoute(let primary, let detail):
      state.navigation.primaryRouteByName[primary.name] = primary
      state.navigation.detailRouteByName[primary.name] = detail
    case .removeRoute(let name):
      state.navigation.primaryRouteByName.removeValue(forKey: name)
      state.navigation.detailRouteByName.removeValue(forKey: name)
    case .beginCaching(let path, let routeName, let isDetail, let policy):
      state = updateRoute(in: state, named: routeName, isDetail: isDetail) { route in
        beginCaching(forRoute: &route, withPath: path, policy: policy)
      }
    case .stopCaching(let path, let routeName, let isDetail):
      state = updateRoute(in: state, named: routeName, isDetail: isDetail) { route in
        stopCaching(route: &route, forPath: path)
      }
    }

    return state
  }

  private func updateRoute(
    in state: State,
    named routeName: String,
    isDetail: Bool,
    updater: (inout NavigationState.RouteState) -> Void
  )
    -> State
  {
    var route =
      (isDetail ? state.navigation.detailRouteByName[routeName] : state.navigation.primaryRouteByName[routeName]) ?? NavigationState.RouteState(name: routeName)
    var state = state

    updater(&route)

    if isDetail {
      state.navigation.detailRouteByName[routeName] = route
    } else {
      state.navigation.primaryRouteByName[routeName] = route
    }

    return state
  }

  /// Begin the routing state.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The new path.
  ///   - skipIfAncestor: If it should skip ancestor paths.
  private func beginRouting(for route: inout NavigationState.RouteState, withPath path: String, skipIfAncestor: Bool) {
    guard
      let resolvedPath = resolvePath(route: route, path: path, skipIfAncestor: skipIfAncestor),
      !skipIfAncestor || !route.path.starts(with: resolvedPath)
    else { return }

    updateRouteLegs(forRoute: &route, withPath: resolvedPath)
    updateCache(forRoute: &route)
  }

  /// Build the legs of a route.
  ///
  /// - Parameters:
  ///   - route: The route to update.
  ///   - path: The route path.
  private func updateRouteLegs(forRoute route: inout NavigationState.RouteState, withPath path: String) {
    let pathComponents = path.split(separator: "/", omittingEmptySubsequences: false)
    var legs = [String: NavigationState.RouteLeg](minimumCapacity: pathComponents.count)
    var orderedLegPaths = [String]()
    var nextLeg = NavigationState.RouteLeg()

    for component in pathComponents.dropFirst().dropLast() {
      nextLeg = nextLeg.append(destination: String(component))
      legs[nextLeg.sourcePath] = nextLeg
      orderedLegPaths.append(nextLeg.sourcePath)
    }

    orderedLegPaths.append(nextLeg.path)

    route = NavigationState.RouteState(
      path: path,
      legsByPath: legs,
      orderedLegPaths: orderedLegPaths,
      caches: route.caches,
      completed: false
    )
  }

  /// Completes the routing state.
  ///
  /// - Parameter route: The route to complete.
  private func completeRouting(route: inout NavigationState.RouteState) {
    route.completed = true
  }

  /// Begin caching child routes for a   path.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The route path that will cache its children.
  ///   - policy: The caching policy.
  private func beginCaching(forRoute route: inout NavigationState.RouteState, withPath path: String, policy: NavigationState.RouteCachingPolicy) {
    guard
      route.caches[path] == nil,
      let pathIndex = route.orderedLegPaths.lastIndex(of: path)
    else { return }

    let sourcePath = route.orderedLegPaths[max(pathIndex - 1, 0)]

    route.caches[path] = NavigationState.RouteCache(
      policy: policy,
      sourcePath: sourcePath,
      path: path
    )
  }

  /// Stop caching child routes for a path.
  ///
  /// - Parameters:
  ///   - route: The current route state.
  ///   - path: The  path.
  private func stopCaching(route: inout NavigationState.RouteState, forPath path: String) {
    route.caches.removeValue(forKey: path)
  }

  /// Updates the route state's cache.
  ///
  /// It adds a new entry to the cache if the current route state has a matching path. It
  /// then removes existing entries who's caching policy has expired.
  /// - Parameter route: The current route state.
  private func updateCache(forRoute route: inout NavigationState.RouteState) {
    var caches = route.caches

    if let cachePath = route.orderedLegPaths.last(where: { caches[$0] != nil }) {
      if let destination = route.legBySourcePath[cachePath]?.destination {
        caches[cachePath]?.snapshots[destination] = route.path
      }
    }

    route.caches = caches.filter { key, cache in
      switch cache.policy {
      case .whileActive:
        return route.path == cache.path || route.legBySourcePath[cache.path] != nil
      case .whileParentActive:
        return route.path == cache.sourcePath || route.legBySourcePath[cache.sourcePath] != nil
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
  private func pathFromCache(route: NavigationState.RouteState, path: String) -> String? {
    guard !route.path.starts(with: path) else { return path }
    let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
    let parentPath = components.dropLast().joined(separator: "/").standardizedPath() ?? "/"
    return components.last.flatMap { route.caches[parentPath]?.snapshots[$0] }
  }

  private func resolvePath(route: NavigationState.RouteState, path: String, skipIfAncestor: Bool) -> String? {
    guard let absolutePath = path.standardizedURL(withBasePath: route.path)?.absoluteString else { return nil }
    return pathFromCache(route: route, path: absolutePath) ?? absolutePath
  }
}
