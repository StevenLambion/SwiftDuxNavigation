import Foundation
import SwiftDux

/// Integrates the navigation into the application state.
public protocol NavigationStateRoot {
  var navigation: NavigationState { get set }
}

/// The state of the navigation system.
public struct NavigationState: Equatable, Codable {
  /// Options of the navigation state.
  public var options: Options = Options()

  /// All primary routes by their name.
  public var primaryRouteByName: [String: RouteState]

  /// All detail routes by their name.
  public var detailRouteByName: [String: RouteState]

  /// The last error received.
  public var lastNavigationError: NavigationError? = nil

  /// The last error message received.
  public var lastNavigationErrorMessage: String? = nil

  /// Initiate a navigation stzate.
  ///
  /// - Parameters:
  ///   - options: Options of the navigation state.
  ///   - primaryRouteByName: The primary routes by name.
  ///   - detailRouteByName: The primary routes by name.
  ///   - lastNavigationError: The last error received.
  ///   - lastNavigationErrorMessage: The last error message received.
  public init(
    options: Options = Options(),
    primaryRouteByName: [String: RouteState] = [:],
    detailRouteByName: [String: RouteState] = [:],
    lastNavigationError: NavigationError? = nil,
    lastNavigationErrorMessage: String? = nil
  ) {
    self.options = options
    self.primaryRouteByName = primaryRouteByName
    self.detailRouteByName = detailRouteByName
    self.lastNavigationError = lastNavigationError
    self.lastNavigationErrorMessage = lastNavigationErrorMessage
  }

  public enum CodingKeys: String, CodingKey {
    case options, primaryRouteByName, detailRouteByName
  }
}

extension NavigationState {

  public static var defaultRouteName = "main"

  /// Options for the NavigationState.
  public struct Options: Equatable, Codable {

    /// The timeout for incomplete routes.
    var completionTimeout: RunLoop.SchedulerTimeType.Stride

    /// Initiate navigation options.
    ///
    /// - Parameter completionTimeout: The timeout for incomplete routes.
    public init(completionTimeout: RunLoop.SchedulerTimeType.Stride = .seconds(1)) {
      self.completionTimeout = completionTimeout
    }
  }
}
