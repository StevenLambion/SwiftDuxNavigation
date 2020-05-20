import Foundation
import SwiftDux

extension NavigationState {
  /// A scene within an application.
  ///
  /// This could represent a window or UIScene object.
  public struct Scene: StateType {

    /// The default main scene of the application.
    public static var defaultName = "main"

    /// The name of the scene.
    public var name: String

    /// The current active route.
    public var route: Route = Route()

    /// The detail route of a scene.
    public var detailRoute: Route = Route()

    /// The route changes should be animated.
    public var animate: Bool = false

    public init(name: String, route: Route = Route(), detailRoute: Route = Route(), animate: Bool = false) {
      self.name = name
      self.route = route
      self.detailRoute = detailRoute
      self.animate = animate
    }
  }
}
