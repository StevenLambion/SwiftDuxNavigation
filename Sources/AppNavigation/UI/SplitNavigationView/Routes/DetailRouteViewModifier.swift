#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DetailRouteViewModifier<DetailContent>: ViewModifier where DetailContent: View {
    @Environment(\.detailRoutes) private var detailRoutes

    var name: String?
    var detailContent: () -> DetailContent

    func body(content: Content) -> some View {
      var detailRoutes = self.detailRoutes
      detailRoutes[name ?? "/"] = AnyView(DetailView(content: detailContent).environment(\.currentRoute, CurrentRoute(path: "/\(name ?? "")/", isDetail: true)))
      return content.environment(\.detailRoutes, detailRoutes)
    }
  }

  extension View {

    /// Create a detail route.
    /// - Parameters:
    ///   - name: The name of the route.
    ///   - detailContent: The content of the route.
    /// - Returns: The view.
    public func detailRoute<V>(_ name: String? = nil, @ViewBuilder detailContent: @escaping () -> V) -> some View where V: View {
      self.modifier(DetailRouteViewModifier(name: name, detailContent: detailContent))
    }
  }

#endif
