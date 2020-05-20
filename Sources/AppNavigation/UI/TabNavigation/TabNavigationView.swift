import SwiftDux
import SwiftUI

/// A tab view that navigates using  routes.
public struct TabNavigationView<Content, T>: View where Content: View, T: LosslessStringConvertible & Hashable {
  @Environment(\.store) private var anyStore
  @MappedDispatch() private var dispatch

  private var content: Content
  private var initialTab: T

  /// Initiate a new `RouteableTabView`.
  /// - Parameters:
  ///   - initialTab: The initial selected tab.
  ///   - content: The contents of the tabView. Use the same API as a SwiftUI `TabView` to set up the tab items.
  public init(initialTab: T, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.initialTab = initialTab
  }

  public var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(routeInfo: RouteInfo) -> some View {
    let pathParameter = createPathParameterBinding(currentRoute: routeInfo.current, pathParameter: routeInfo.pathParameter)
    let shouldRedirect = routeInfo.fullPath == routeInfo.current.path
    return TabView(selection: pathParameter) { content.provideStore(anyStore) }
      .environment(\.currentRoute, routeInfo.current.next(with: String(pathParameter.wrappedValue)))
      .onAppear {
        if shouldRedirect {
          self.dispatch(routeInfo.current.navigate(to: String(pathParameter.wrappedValue), animate: false))
        }
        self.dispatch(routeInfo.current.beginCaching())
      }
  }

  private func createPathParameterBinding(currentRoute: CurrentRoute, pathParameter: String?) -> Binding<T> {
    let pathParameter = pathParameter.flatMap { T($0) } ?? initialTab
    return Binding(
      get: { pathParameter },
      set: {
        let nextPathParam = String($0)
        self.dispatch(currentRoute.navigate(to: String(nextPathParam)))
        self.dispatch(currentRoute.completeNavigation())
      }
    )
  }
}
