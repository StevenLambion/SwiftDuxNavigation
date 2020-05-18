#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeSplitNavigationView<MasterContent>: UIViewControllerRepresentable
  where MasterContent: View {
    @Environment(\.splitNavigationOptions) private var splitNavigationOptions
    @Environment(\.detailRoutes) private var detailRoutes
    @Environment(\.currentRoute) private var currentRoute
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var activeDetailRoute: String?
    var animate: Bool
    var masterContent: MasterContent

    func makeUIViewController(context: Context) -> UISplitViewController {
      let coordinator = context.coordinator
      let splitViewController = UISplitViewController()
      coordinator.splitViewController = splitViewController
      return splitViewController
    }

    /// Cleans up the presented `UIViewController` (and coordinator) in
    /// anticipation of their removal.
    static func dismantleUIViewController(
      _ uiViewController: UISplitViewController,
      coordinator: NativeSplitNavigationViewCoordinator<MasterContent>
    ) {}

    func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
      context.coordinator.splitNavigationOptions = splitNavigationOptions
      context.coordinator.detailRoutes = detailRoutes
      context.coordinator.activeDetailRoute = activeDetailRoute
      context.coordinator.currentRoute = currentRoute
      context.coordinator.animate = animate
      context.coordinator.isCollapsed = horizontalSizeClass == .compact
      context.coordinator.setMasterContent(masterContent)
    }

    func makeCoordinator() -> NativeSplitNavigationViewCoordinator<MasterContent> {
      let coordinator = NativeSplitNavigationViewCoordinator<MasterContent>()
      coordinator.splitNavigationOptions = splitNavigationOptions
      coordinator.detailRoutes = detailRoutes
      coordinator.activeDetailRoute = activeDetailRoute
      coordinator.currentRoute = currentRoute
      coordinator.animate = animate
      coordinator.isCollapsed = horizontalSizeClass == .compact
      coordinator.setMasterContent(masterContent)

      return coordinator
    }
  }

#endif
