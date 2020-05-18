import SwiftDux
import SwiftUI

/// A tab view that navigates using  routes.
///
/// TODO - Persist tab state
public struct TabNavigationView<Content, T>: View where Content: View, T: LosslessStringConvertible & Hashable {
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

  private func routeContents(currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
    let pathParam = self.getPathParam(currentRoute: currentRoute, leg: leg)
    return Redirect(path: String(pathParam.wrappedValue)) {
      TabView(selection: pathParam) { content }
        .environment(\.currentRoute, currentRoute.next(with: String(pathParam.wrappedValue)))
    }
  }

  private func getPathParam(currentRoute: CurrentRoute, leg: RouteLeg?) -> Binding<T> {
    let pathParam = leg.flatMap { T($0.component) } ?? initialTab
    return Binding(
      get: { pathParam },
      set: { self.dispatch(currentRoute.navigate(to: String($0))) }
    )
  }
}
