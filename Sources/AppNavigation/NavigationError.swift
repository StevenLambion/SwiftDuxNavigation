import Foundation

public enum NavigationError: Error, Equatable {
  case unknown
  case sceneNotFound(scene: String)
  case routeCompletionFailed(scene: String, isDetail: Bool)
}
