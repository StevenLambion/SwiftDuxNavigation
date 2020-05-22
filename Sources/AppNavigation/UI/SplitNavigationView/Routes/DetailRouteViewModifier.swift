#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DetailRouteViewModifier<DetailContent>: ViewModifier where DetailContent: View {
    @Environment(\.detailRoutes) private var detailRoutes

    var name: String?
    var detailContent: DetailContent

    private var detailPath: String {
      guard let name = name, !name.isEmpty else {
        return "/"
      }
      return "/\(name)/"
    }

    func body(content: Content) -> some View {
      var detailRoutes = self.detailRoutes
      detailRoutes[name ?? "/"] = {
        AnyView(
          DetailView(content: { self.detailContent }).resetRoute(with: self.detailPath, isDetail: true)
        )
      }
      return content.environment(\.detailRoutes, detailRoutes)
    }
  }

  extension View {

    /// Create a detail route.
    /// 
    /// - Parameters:
    ///   - name: The name of the route.
    ///   - content: The content of the route.
    /// - Returns: The view.
    public func detailRoute<Content>(_ name: String? = nil, @ViewBuilder content: () -> Content) -> some View where Content: View {
      self.modifier(DetailRouteViewModifier(name: name, detailContent: content()))
    }
  }

#endif
