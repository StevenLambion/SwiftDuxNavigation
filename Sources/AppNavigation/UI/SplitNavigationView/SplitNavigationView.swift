#if canImport(UIKit)
  import SwiftDux
  import SwiftUI

  /// Create a master-detail style split navigation view.
  public struct SplitNavigationView<MasterContent>: ConnectableView where MasterContent: View {
    @Environment(\.waypoint) private var waypoint
    @MappedDispatch() private var dispatch

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

      /// Should the navigation complete.
      var shouldComplete: Bool
    }

    public func map(state: NavigationStateRoot) -> Props? {
      guard let scene = waypoint.resolveSceneState(in: state) else { return nil }
      guard let route = waypoint.resolveState(in: state) else { return nil }
      return Props(
        activeDetailRoute: scene.detailRoute.legsByPath["/"]?.component ?? "/",
        animate: scene.animate,
        shouldComplete: waypoint.shouldComplete(for: route)
      )
    }

    public func body(props: Props) -> some View {
      if props.shouldComplete {
        dispatch(waypoint.completeNavigation())
      }
      return NativeSplitNavigationView(
        activeDetailRoute: props.activeDetailRoute,
        animate: props.animate,
        masterContent: masterContent
      ).edgesIgnoringSafeArea(.all)
    }
  }
#endif
