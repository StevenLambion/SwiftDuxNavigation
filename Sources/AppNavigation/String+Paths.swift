import Foundation

extension String {

  /// Creates a standardized, absolute URL from a path and an optional base path.
  ///
  /// - Parameter basePath: An optional base path to extend from.
  /// - Returns: The standardized URL.
  public func standardizedURL(withBasePath basePath: String = "/") -> URL? {
    let path = self.last == "/" ? self : self + "/"
    let basePath = basePath.last == "/" ? basePath : basePath + "/"

    if path.starts(with: "/") {
      return URL(string: path)?.standardized
    }

    return URL(string: "\(basePath)\(path)")?.standardized
  }

  /// Creates a standardized, absolute path string from a path and an optional base path.
  ///
  /// - Parameter basePath: An optional base path to extend from.
  /// - Returns: The standardized path.
  public func standardizedPath(withBasePath basePath: String = "/") -> String? {
    standardizedURL(withBasePath: basePath)?.absoluteString
  }

  static func routePath(withName name: String, primaryPath: String = "", detailPath: String = "") -> String {
    "\(name)\(primaryPath)\(!detailPath.isEmpty ? "#\(detailPath)" : "")"
  }

  static func routePath(withRoute route: NavigationState.RouteState, isDetail: Bool = false) -> String {
    String.routePath(
      withName: route.name,
      primaryPath: isDetail ? "" : route.path,
      detailPath: isDetail ? route.path : ""
    )
  }
}
