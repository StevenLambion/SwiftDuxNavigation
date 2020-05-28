import SwiftDux
import SwiftUI

internal struct DynamicRootDetailWaypointViewModifier<T, DetailContent>: WaypointResolverViewModifier
where T: LosslessStringConvertible & Equatable, DetailContent: View {
  @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent

  static var hasPathParameter: Bool { true }
  var isDetail: Bool? { true }

  var name: String?
  var detailContent: (T) -> DetailContent

  func body(content: Content, info: ResolvedWaypointInfo) -> some View {
    let pathParameter = info.pathParameter(as: T.self)
    let activate = pathParameter != nil && rootDetailWaypointContent == nil && info.active
    return
      content
      .environment(
        \.rootDetailWaypointContent,
        activate
          ? RootDetailWaypointContent(
            waypoint: info.nextWaypoint,
            animate: info.animate,
            content: detailContent(pathParameter!).waypoint(with: info.nextWaypoint)
          )
          : rootDetailWaypointContent
      )
  }
}

extension View {

  /// Create a detail waypoint that accepts a parameter.
  /// 
  /// - Parameters:
  ///   - name: The name of the route.
  ///   - content: The content of the route.
  /// - Returns: The view.
  public func detailItem<T, Content>(_ name: String? = nil, @ViewBuilder content: @escaping (T) -> Content) -> some View
  where T: LosslessStringConvertible & Equatable, Content: View {
    self.modifier(DynamicRootDetailWaypointViewModifier(name: name, detailContent: content))
  }
}
