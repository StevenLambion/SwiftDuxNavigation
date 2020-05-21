#if canImport(UIKit)
  import SwiftDux
  import SwiftUI

  /// Create a master-detail style split navigation view.
  public struct SplitNavigationView<MasterContent>: ConnectableView where MasterContent: View {
    @Environment(\.waypoint) private var waypoint

    private var masterContent: MasterContent

    /// Initiate a `SplitNavigationView` with a root view.
    /// 
    /// - Parameter masterContent: The master view.
    public init(@ViewBuilder masterContent: () -> MasterContent) {
      self.masterContent = masterContent()
    }

    public struct Props: Equatable {

      /// The root path of the navigation stack.
      var activeDetailRoute: String?

      /// Should the navigation animate.
      var animate: Bool
    }

    public func map(state: NavigationStateRoot) -> Props? {
      guard let scene = waypoint.resolveSceneState(in: state) else { return nil }
      return Props(
        activeDetailRoute: scene.detailRoute.legsByPath["/"]?.component ?? "/",
        animate: scene.animate
      )
    }

    public func body(props: Props) -> some View {
      NativeSplitNavigationView(
        activeDetailRoute: props.activeDetailRoute,
        animate: props.animate,
        masterContent: masterContent
      ).edgesIgnoringSafeArea(.all)
    }
  }
#endif
