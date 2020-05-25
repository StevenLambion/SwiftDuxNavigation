import Foundation

public enum NavigationError: Error, Equatable {
  case unknown
  case sceneNotFound
  case routeCompletionFailed(scene: String, isDetail: Bool)
}
