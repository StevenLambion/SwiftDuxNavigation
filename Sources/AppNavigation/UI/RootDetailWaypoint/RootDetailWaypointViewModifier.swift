#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct RootDetailWaypointViewModifier<DetailContent>: WaypointResolverViewModifier where DetailContent: View {
    @MappedDispatch() private var dispatch
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent
    var isDetail: Bool? { true }

    var name: String?
    var detailContent: DetailContent

    func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      let path = name.map { "/\($0)/" } ?? "/"
      let activate = rootDetailWaypointContent == nil && info.active
      return
        content
        .environment(
          \.rootDetailWaypointContent,
          activate
            ? RootDetailWaypointContent(path: path, content: detailContent)
            : rootDetailWaypointContent
        )
    }
  }

  extension View {

    /// Create a detail waypoint.
    /// 
    /// - Parameters:
    ///   - name: The name of the route.
    ///   - content: The content of the route.
    /// - Returns: The view.
    public func detailItem<Content>(_ name: String? = nil, @ViewBuilder content: () -> Content) -> some View where Content: View {
      self.modifier(RootDetailWaypointViewModifier(name: name, detailContent: content()))
    }
  }

#endif
