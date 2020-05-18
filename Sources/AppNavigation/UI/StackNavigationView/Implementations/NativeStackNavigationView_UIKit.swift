#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeStackNavigationView<RootView>: UIViewControllerRepresentable
  where RootView: View {
    @Environment(\.currentRoute) private var currentRoute
    @Environment(\.splitNavigationDisplayModeButton) private var splitNavigationDisplayModeButton
    @MappedDispatch() private var dispatch

    var animate: Bool
    var rootView: RootView

    func makeUIViewController(context: Context) -> UINavigationController {
      let coordinator = context.coordinator
      let navigationController = UINavigationController()
      coordinator.navigationController = navigationController
      return navigationController
    }

    /// Cleans up the presented `UIViewController` (and coordinator) in
    /// anticipation of their removal.
    static func dismantleUIViewController(
      _ uiViewController: UINavigationController,
      coordinator: StackNavigationCoordinator
    ) {}

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
      context.coordinator.setRootView(rootView: rootView)
      context.coordinator.currentRoute = currentRoute
      context.coordinator.animate = animate
      context.coordinator.splitNavigationDisplayModeButton = splitNavigationDisplayModeButton
    }

    func makeCoordinator() -> StackNavigationCoordinator {
      let coordinator = StackNavigationCoordinator(dispatch: dispatch)
      coordinator.setRootView(rootView: rootView)
      coordinator.currentRoute = currentRoute
      coordinator.animate = animate
      coordinator.splitNavigationDisplayModeButton = splitNavigationDisplayModeButton
      return coordinator
    }
  }

#endif
