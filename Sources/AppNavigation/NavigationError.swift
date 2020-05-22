import Foundation

public enum NavigationError: String, Error, Codable {
  case unknown
  case sceneNotFound
  case routeCompletionFailed
}
