import Foundation
import SwiftDux

extension NavigationState {

  /// A single route leg as a segment of the route.
  public struct RouteLeg: Equatable, Codable {

    /// The parent path of the leg.
    public var sourcePath: String

    /// The name of the leg's destination.
    public var destination: String

    /// The index of the leg.
    public var index: Int

    /// The full path of a leg.
    public var path: String {
      destination.isEmpty ? sourcePath : "\(sourcePath)\(destination)/"
    }

    /// Initiate a RouteLeg state.
    ///
    /// - Parameters:
    ///   - sourcePath: The parent path of the leg.
    ///   - destination: The name of the leg's destination.
    ///   - index: The index of the leg.
    public init(sourcePath: String = "/", destination: String = "", index: Int = 0) {
      self.sourcePath = sourcePath
      self.destination = destination
      self.index = index
    }

    /// Append a destination to form a new leg.
    ///
    /// - Parameter destination: The next destination.
    /// - Returns: A new `RouteLeg`.
    public func append(destination: String) -> RouteLeg {
      RouteLeg(
        sourcePath: path,
        destination: destination,
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
  public struct RouteCache: Equatable, Codable {
    public var policy: RouteCachingPolicy
    public var sourcePath: String
    public var path: String
    public var snapshots: [String: String] = [:]
  }

  /// A route within the application.
  public struct RouteState: Equatable, Codable {

    /// The absolute path of the route.
    public var name: String

    /// The absolute path of the route.
    public var path: String

    /// All the legs of the route by their source path.
    public var legBySourcePath: [String: RouteLeg]

    /// An ordered list of all the legs' absolute paths.
    public var orderedLegPaths: [String]

    /// The last leg of the route.
    public var lastLeg: RouteLeg {
      let index = min(0, orderedLegPaths.count - 2)
      return legBySourcePath[orderedLegPaths[index]] ?? RouteLeg()
    }

    /// The route caches by their path.
    public var caches: [String: RouteCache]

    /// The route changes have completed.
    public var completed: Bool = false

    public init(
      name: String = NavigationState.defaultRouteName,
      path: String = "/",
      legsByPath: [String: RouteLeg] = [:],
      orderedLegPaths: [String] = [],
      caches: [String: RouteCache] = [:],
      completed: Bool = false
    ) {
      self.name = name
      self.path = path
      self.legBySourcePath = legsByPath
      self.orderedLegPaths = orderedLegPaths
      self.caches = caches
      self.completed = completed
    }

    public enum CodingKeys: String, CodingKey {
      case name, path, legBySourcePath, orderedLegPaths, caches
    }
  }
}
