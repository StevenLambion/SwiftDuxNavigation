#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicDetailRouteViewModifier<T, DetailContent>: ViewModifier
  where T: LosslessStringConvertible & Equatable, DetailContent: View {
    @Environment(\.detailRoutes) private var detailRoutes

    var name: String?
    var detailContent: (T) -> DetailContent

    func body(content: Content) -> some View {
      var detailRoutes = self.detailRoutes
      detailRoutes[name ?? "/"] = {
        AnyView(
          DynamicDetailView(content: self.detailContent)
            .environment(\.currentRoute, CurrentRoute(path: "/\(self.name ?? "")/", isDetail: true))
        )
      }
      return content.environment(\.detailRoutes, detailRoutes)
    }
  }

  extension View {

    /// Create a detail route that accepts a parameter.
    /// - Parameters:
    ///   - name: The name of the route.
    ///   - detailContent: The content of the route.
    /// - Returns: The view.
    public func detailRoute<T, V>(_ name: String? = nil, @ViewBuilder detailContent: @escaping (T) -> V) -> some View
    where T: LosslessStringConvertible & Equatable, V: View {
      self.modifier(DynamicDetailRouteViewModifier(name: name, detailContent: detailContent))
    }
  }

#endif
