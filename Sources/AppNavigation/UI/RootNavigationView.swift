#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  /// Setup any required navigation.
  ///
  /// This should be placed at the root of the application or scene. Any environment objects must be added outside of this
  /// view, so they will propagate down to all view heirarchies.
  public struct RootNavigationView<RootView>: View where RootView: View {
    public var rootView: RootView

    public init(@ViewBuilder rootView: () -> RootView) {
      self.rootView = rootView()
    }

    public var body: some View {
      RootNavigationHostingView {
        rootView
      }
      .edgesIgnoringSafeArea(.all)
    }
  }

  internal struct RootNavigationHostingView<RootView>: UIViewControllerRepresentable where RootView: View {
    var rootView: RootView

    init(@ViewBuilder rootView: () -> RootView) {
      self.rootView = rootView()
    }

    func makeUIViewController(context: Context) -> UIHostingController<RootView> {
      return UIHostingController(rootView: rootView)
    }

    /// Cleans up the presented `UIViewController` (and coordinator) in
    /// anticipation of their removal.
    static func dismantleUIViewController(
      _ uiViewController: UIHostingController<RootView>,
      coordinator: RootNavigationViewCooordinator
    ) {}

    func updateUIViewController(_ uiViewController: UIHostingController<RootView>, context: Context) {
    }

    func makeCoordinator() -> RootNavigationViewCooordinator {
      return RootNavigationViewCooordinator()
    }
  }

  extension RootNavigationHostingView {

    /// Currently not implemented.
    class RootNavigationViewCooordinator {

    }
  }

#endif
