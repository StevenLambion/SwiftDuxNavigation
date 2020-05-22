#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  /// Create a stack-style navigation.
  public struct StackNavigationView<RootView>: RouteReaderView where RootView: View {
    @Environment(\.waypoint) private var waypoint

    private var rootView: RootView

    /// Initiate a `StackNavigationView` with a root view.
    /// - Parameter rootView: The root view of the stack.
    public init(@ViewBuilder rootView: () -> RootView) {
      self.rootView = rootView()
    }

    public func body(routeInfo: RouteInfo) -> some View {
      NativeStackNavigationView(
        animate: routeInfo.animate,
        rootView: rootView
      )
      .opacity(!routeInfo.animate && !routeInfo.completed ? 0 : 1)
      .edgesIgnoringSafeArea(.all)
    }
  }

#endif
