import Foundation

/// Navigation errors.
public enum NavigationError: Error, Equatable {
  case unknown

  /// A route failed to resolve within the timeout limit.
  case routeCompletionFailed(route: String, isDetail: Bool)
}
