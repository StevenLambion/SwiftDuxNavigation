#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  /// Setup any required navigation.
  ///
  /// This should be placed at the root of the application or scene. Any environment objects must be added outside of this
  /// view, so they will propagate down to all view heirarchies.
  public struct RootNavigationView<RootView>: UIViewControllerRepresentable where RootView: View {
    public var rootView: RootView

    public init(@ViewBuilder rootView: () -> RootView) {
      self.rootView = rootView()
    }

    public func makeUIViewController(context: Context) -> UIHostingController<RootView> {
      return UIHostingController(rootView: rootView)
    }

    /// Cleans up the presented `UIViewController` (and coordinator) in
    /// anticipation of their removal.
    public static func dismantleUIViewController(
      _ uiViewController: UIHostingController<RootView>,
      coordinator: RootNavigationViewCooordinator
    ) {}

    public func updateUIViewController(_ uiViewController: UIHostingController<RootView>, context: Context) {
    }

    public func makeCoordinator() -> RootNavigationViewCooordinator {
      return RootNavigationViewCooordinator()
    }
  }

  extension RootNavigationView {

    /// Currently not implemented.
    public class RootNavigationViewCooordinator {

    }
  }

#endif
