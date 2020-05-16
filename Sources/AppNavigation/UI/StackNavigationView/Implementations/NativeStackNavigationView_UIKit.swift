#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeStackNavigationView<RootView>: UIViewControllerRepresentable
  where RootView: View {
    @Environment(\.routeInfo) private var routeInfo
    @MappedDispatch() private var dispatch

    var rootPath: String
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
      context.coordinator.rootPath = rootPath
      context.coordinator.animate = animate
    }

    func makeCoordinator() -> StackNavigationCoordinator {
      let coordinator = StackNavigationCoordinator(dispatch: dispatch)
      coordinator.setRootView(rootView: rootView)
      coordinator.rootPath = rootPath
      coordinator.animate = animate

      return coordinator
    }
  }

#endif
