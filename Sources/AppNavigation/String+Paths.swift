import Foundation

extension String {

  /// Creates a standardized, absolute URL from a path and an optional base path.
  /// - Parameter basePath: An optional base path to extend from.
  /// - Returns: The standardized URL.
  public func standardizedURL(withBasePath basePath: String = "/") -> URL? {
    let path = self.last == "/" ? self : self + "/"
    let basePath = basePath.last == "/" ? basePath : basePath + "/"
    guard !path.starts(with: "/") else { return URL(string: path)?.standardized }
    return URL(string: "\(basePath)\(path)")?.standardized
  }

  /// Creates a standardized, absolute path string from a path and an optional base path.
  /// - Parameter basePath: An optional base path to extend from.
  /// - Returns: The standardized path.
  public func standardizedPath(withBasePath basePath: String = "/") -> String? {
    standardizedURL(withBasePath: basePath)?.absoluteString
  }
}
