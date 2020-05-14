import SwiftDux
import SwiftUI

/// Create a stack-style navigation.
public struct StackNavigationView<RootView>: ConnectableView where RootView: View {
  @Environment(\.routeInfo) private var routeInfo

  private var rootView: RootView

  /// Initiate a `StackNavigationView` with a root view.
  /// - Parameter rootView: The root view of the stack.
  public init(@ViewBuilder rootView: () -> RootView) {
    self.rootView = rootView()
  }

  public struct Props: Equatable {

    /// The root path of the navigation stack.
    var rootPath: String

    /// Should the navigation animate.
    var animate: Bool

    /// Hides the navigation view when not animating and the route has completed.
    /// This stops the UINavigationController from flashing view controllers before the
    /// destination one.
    var hide: Bool
  }

  public func map(state: NavigationStateRoot) -> Props? {
    guard let route = routeInfo.resolve(in: state) else { return nil }
    return Props(
      rootPath: routeInfo.path,
      animate: route.animate,
      hide: !route.animate && !route.completed && route.lastLeg.path != routeInfo.path
    )
  }

  public func body(props: Props) -> some View {
    NativeStackNavigationView(
      rootPath: props.rootPath,
      animate: props.animate,
      rootView: rootView
    )
    //.edgesIgnoringSafeArea(.top)
    //.opacity(props.hide ? 0 : 1)
  }
}
