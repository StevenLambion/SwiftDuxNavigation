#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeStackNavigationView<RootView>: UIViewControllerRepresentable
  where RootView: View {
    @Environment(\.waypoint) private var waypoint
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent
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
      context.coordinator.waypoint = waypoint
      context.coordinator.animate = animate
      context.coordinator.setRootView(rootView: rootView, isDetail: false)
      context.coordinator.setRootView(rootView: rootDetailWaypointContent?.view, isDetail: true)
      context.coordinator.updateNavigation()
    }

    func makeCoordinator() -> StackNavigationCoordinator {
      return StackNavigationCoordinator(
        dispatch: dispatch,
        waypoint: waypoint,
        detailContent: rootDetailWaypointContent?.view,
        animate: animate,
        rootView: rootView
      )
    }
  }

#endif
