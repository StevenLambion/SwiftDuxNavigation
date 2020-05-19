import Foundation
import SwiftDux

/// Integrates the navigation into the application state.
public protocol NavigationStateRoot {
  var navigation: NavigationState { get set }
}

/// A single route leg as a segment of the route.
public struct RouteLeg: StateType {
  /// The parent path of the leg.
  public var parentPath: String

  /// The component of this leg.
  public var component: String

  /// The index of the leg.
  public var index: Int

  public var path: String {
    component.isEmpty ? parentPath : "\(parentPath)\(component)/"
  }

  public init(parentPath: String = "/", component: String = "", index: Int = 0) {
    self.parentPath = parentPath
    self.component = component
    self.index = index
  }

  /// /// Append a component to form a new leg.
  /// - Parameter component: The component to append.
  /// - Returns: A new `RouteLeg`.
  public func append(component: String) -> RouteLeg {
    RouteLeg(
      parentPath: path,
      component: component,
      index: index + 1
    )
  }
}

/// An active route of a scene.
public struct RouteState: StateType {

  /// The absolute path of the route.
  public var path: String

  /// All the legs of the route by their parent path.
  public var legsByPath: [String: RouteLeg]

  /// The last leg of the route.
  public var lastLeg: RouteLeg

  /// The route changes have completed.
  public var completed: Bool = false

  public init(
    path: String = "/",
    legsByPath: [String: RouteLeg] = [:],
    lastLeg: RouteLeg = RouteLeg(parentPath: "/", component: ""),
    completed: Bool = false
  ) {
    self.path = path
    self.legsByPath = legsByPath
    self.lastLeg = lastLeg
    self.completed = completed
  }

  public enum CodingKeys: String, CodingKey {
    case path, legsByPath, lastLeg
  }
}

public struct RouteSnapshot: StateType {
  public var id: String
  public var path: String
  public var isDetail: Bool
}

/// A scene within an application.
///
/// This could represent a window or UIScene object.
public struct SceneState: StateType {

  /// The default main scene of the application.
  public static var mainSceneName = "main"

  /// The name of the scene.
  public var name: String

  /// The current active route.
  public var route: RouteState = RouteState()

  /// The detail route of a scene.
  public var detailRoute: RouteState = RouteState()

  /// The route changes should be animated.
  public var animate: Bool = false

  /// Snapshots of routes. Each bucket is stored by their parent route path.
  /// The storing route provides an identifier for each RouteState it wants to store.
  public var snapshots: [String: [String: RouteSnapshot]] = [:]

  public init(name: String, route: RouteState = RouteState(), detailRoute: RouteState = RouteState(), animate: Bool = false) {
    self.name = name
    self.route = route
    self.detailRoute = detailRoute
    self.animate = animate
  }

  func snapshotKey(forPath path: String, isDetail: Bool) -> String {
    isDetail ? "#\(path)" : path
  }

  func hasSnapshot(forPath path: String, isDetail: Bool, identifier: String) -> Bool {
    snapshots[snapshotKey(forPath: path, isDetail: isDetail)]?[identifier] != nil
  }
}

/// The state of the navigation system.
public struct NavigationState: StateType {

  /// All scenes by their name.
  public var sceneByName: [String: SceneState] = [
    SceneState.mainSceneName: SceneState(name: SceneState.mainSceneName)
  ]

  public init(
    sceneByName: [String: SceneState] = [
      SceneState.mainSceneName: SceneState(name: SceneState.mainSceneName)
    ]
  ) {
    self.sceneByName = sceneByName
  }
}
