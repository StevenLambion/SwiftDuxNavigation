#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeSplitNavigationView<MasterContent>: UIViewControllerRepresentable
  where MasterContent: View {
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent
    @Environment(\.waypoint) private var waypoint
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
      context.coordinator.rootDetailWaypointContent = rootDetailWaypointContent
      context.coordinator.waypoint = waypoint
      context.coordinator.isCollapsed = horizontalSizeClass == .compact
      context.coordinator.setMasterContent(masterContent)
    }

    func makeCoordinator() -> NativeSplitNavigationViewCoordinator<MasterContent> {
      return NativeSplitNavigationViewCoordinator<MasterContent>(
        rootDetailWaypointContent: rootDetailWaypointContent,
        waypoint: waypoint,
        isCollapsed: horizontalSizeClass == .compact,
        masterContent: masterContent
      )
    }
  }

#endif
