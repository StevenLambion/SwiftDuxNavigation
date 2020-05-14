import Foundation

extension String {

  public func standardizePath(withBasePath basePath: String = "/") -> String? {
    let path = self.last == "/" ? self : self + "/"
    let basePath = basePath.last == "/" ? basePath : basePath + "/"
    guard !path.starts(with: "/") else { return path }
    return URL(string: "\(basePath)\(path)")?.standardized.absoluteString
  }
}
