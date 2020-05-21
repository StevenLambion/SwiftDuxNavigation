import Foundation
import SwiftDux

extension NavigationState {
  /// A single route leg as a segment of the route.
  public struct RouteLeg: StateType {
    /// The parent path of the leg.
    public var parentPath: String

    /// The component of this leg.
    public var component: String

    /// The index of the leg.
    public var index: Int

    /// The full path of a leg.
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

  /// The policy for clearing the caches.
  public enum RouteCachingPolicy: String, Codable {
    case forever
    case whileActive
    case whileParentActive
  }

  /// Cache for a route to save it's child routes.
  public struct RouteCache: StateType {
    public var policy: RouteCachingPolicy
    public var parentPath: String
    public var path: String
    public var snapshots: [String: String] = [:]
  }

  /// An active route of a scene.
  public struct Route: StateType {

    /// The absolute path of the route.
    public var path: String

    /// All the legs of the route by their parent path.
    public var legsByPath: [String: RouteLeg]

    /// An ordered list of all the legs' absolute paths.
    public var orderedLegPaths: [String]

    /// The last leg of the route.
    public var lastLeg: RouteLeg {
      orderedLegPaths.last.flatMap { legsByPath[$0] } ?? RouteLeg()
    }

    /// The route caches by their path.
    public var caches: [String: RouteCache]

    /// The route changes have completed.
    public var completed: Bool = false

    public init(
      path: String = "/",
      legsByPath: [String: RouteLeg] = [:],
      orderedLegPaths: [String] = [],
      caches: [String: RouteCache] = [:],
      completed: Bool = false
    ) {
      self.path = path
      self.legsByPath = legsByPath
      self.orderedLegPaths = orderedLegPaths
      self.caches = caches
      self.completed = completed
    }

    public enum CodingKeys: String, CodingKey {
      case path, legsByPath, orderedLegPaths, caches
    }
  }
}
