#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeSplitNavigationView<MasterContent>: UIViewControllerRepresentable
  where MasterContent: View {
    @Environment(\.store) private var store
    @Environment(\.detailRoutes) private var detailRoutes
    @Environment(\.waypoint) private var waypoint
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
      context.coordinator.store = store
      context.coordinator.detailRoutes = detailRoutes
      context.coordinator.waypoint = waypoint
      context.coordinator.isCollapsed = horizontalSizeClass == .compact
      context.coordinator.activeDetailRoute = activeDetailRoute
      context.coordinator.setMasterContent(masterContent)
    }

    func makeCoordinator() -> NativeSplitNavigationViewCoordinator<MasterContent> {
      return NativeSplitNavigationViewCoordinator<MasterContent>(
        store: store,
        detailRoutes: detailRoutes,
        activeDetailRoute: activeDetailRoute,
        waypoint: waypoint,
        isCollapsed: horizontalSizeClass == .compact,
        masterContent: masterContent
      )
    }
  }

#endif
