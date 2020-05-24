import SwiftDux
import SwiftUI

/// A tab view that navigates using  routes.
public struct TabNavigationView<Content, T>: WaypointResolverView where Content: View, T: LosslessStringConvertible & Hashable {
  public static var hasPathParameter: Bool { true }
  public var defaultPathParameter: String? { String(initialTab) }

  @MappedDispatch() private var dispatch

  private var content: Content
  private var initialTab: T

  /// Initiate a new `TabNavigationView`.
  ///
  /// - Parameters:
  ///   - initialTab: The initial selected tab.
  ///   - content: The contents of the tabView. Use the same API as a SwiftUI `TabView` to set up the tab items.
  public init(initialTab: T, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.initialTab = initialTab
  }

  public func body(info: ResolvedWaypointInfo) -> some View {
    TabView(selection: selection(with: info.waypoint, pathParameter: info.pathParameter(as: T.self) ?? initialTab)) {
      content.waypoint(with: info.nextWaypoint)
    }
    .onAppear { self.dispatch(info.waypoint.beginCaching()) }
  }

  private func selection(with waypoint: Waypoint, pathParameter: T) -> Binding<T> {
    Binding(
      get: { pathParameter },
      set: {
        self.dispatch(waypoint.navigate(to: $0, animate: false))
        self.dispatch(waypoint.completeNavigation())
      }
    )
  }
}

extension View {

  /// Add a new tab item by name.
  ///
  /// This is a convenience method that combines the regular tabItem view modifier with the tag view modifier.
  /// - Parameters:
  ///   - name: The name of the tab.
  ///   - content: The contents of the tab item.
  /// - Returns: The view.
  public func tabItem<Content>(_ name: String, @ViewBuilder content: () -> Content) -> some View where Content: View {
    self.tabItem(content).tag(name)
  }
}
