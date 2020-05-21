import SwiftDux
import SwiftUI

internal struct DynamicDetailView<Content, T>: RouteReaderView where Content: View, T: LosslessStringConvertible & Equatable {
  private var content: (T) -> Content

  init(@ViewBuilder content: @escaping (T) -> Content) {
    self.content = content
  }

  public func body(routeInfo: RouteInfo) -> some View {
    let pathParameter = routeInfo.pathParameter.flatMap { !$0.isEmpty ? T($0) : nil }
    return Group {
      if pathParameter != nil {
        content(pathParameter!).nextWaypoint(with: pathParameter!)
      }
    }
  }
}
