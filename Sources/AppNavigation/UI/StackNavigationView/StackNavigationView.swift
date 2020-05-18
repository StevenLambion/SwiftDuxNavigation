#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  /// Create a stack-style navigation.
  public struct StackNavigationView<RootView>: ConnectableView where RootView: View {
    @Environment(\.currentRoute) private var currentRoute

    private var rootView: RootView

    /// Initiate a `StackNavigationView` with a root view.
    /// - Parameter rootView: The root view of the stack.
    public init(@ViewBuilder rootView: () -> RootView) {
      self.rootView = rootView()
    }

    public struct Props: Equatable {

      /// Should the navigation animate.
      var animate: Bool

      /// Hides the navigation view when not animating and the route has completed.
      /// This stops the UINavigationController from flashing view controllers before the
      /// destination one.
      var hide: Bool
    }

    public func map(state: NavigationStateRoot) -> Props? {
      guard let scene = currentRoute.resolveSceneState(in: state) else { return nil }
      guard let route = currentRoute.resolveState(in: state) else { return nil }
      return Props(
        animate: scene.animate,
        hide: !scene.animate && !route.completed && route.lastLeg.path != currentRoute.path
      )
    }

    public func body(props: Props) -> some View {
      NativeStackNavigationView(
        animate: props.animate,
        rootView: rootView
      )
      .opacity(props.hide ? 0 : 1)
    }
  }

#endif
