import SwiftDux
import SwiftUI

struct StackRouteBuilder<Content, BranchView>: ConnectableView
where Content: View, BranchView: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  var content: Content
  var branchView: () -> BranchView

  struct Props: Equatable {
    var route: RouteState
    var isActive: Bool
  }

  func map(state: NavigationStateRoot) -> Props? {
    guard let route = routeInfo.resolve(in: state) else { return nil }
    return Props(
      route: route,
      isActive: routeInfo.resolveLeg(in: state) != nil
    )
  }

  func body(props: Props) -> some View {
    RouteContents(route: props.route) {
      if props.isActive {
        content.stackRoutePreference([createRoute()])
      } else {
        content
      }
    }
  }

  func createRoute() -> StackRoute {
    StackRoute(
      path: routeInfo.path,
      fromBranch: routeInfo.isBranch,
      view: branchView()
    )
  }
}

extension View {

  func addStackRoute<V>(@ViewBuilder branchView: @escaping () -> V) -> some View where V: View {
    StackRouteBuilder(content: self, branchView: branchView)
  }
}
