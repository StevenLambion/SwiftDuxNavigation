import SwiftDux
import SwiftUI

struct StackRouteBuilder<Content, BranchView>: ConnectableView
where Content: View, BranchView: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  var content: Content
  var branchView: () -> BranchView

  struct Props: Equatable {
    var isActive: Bool
    var isLastRoute: Bool
    var completed: Bool
  }

  func map(state: NavigationStateRoot) -> Props? {
    guard let route = routeInfo.resolve(in: state) else { return nil }
    return Props(
      isActive: routeInfo.resolveLeg(in: state) != nil,
      isLastRoute: routeInfo.path == route.lastLeg.parentPath,
      completed: route.completed
    )
  }

  func body(props: Props) -> some View {
    Group {
      if props.isActive {
        content
          .preference(
            key: StackRoutePreferenceKey.self,
            value: [createRoute()]
          )
          .onAppear {
            if !props.completed && props.isLastRoute {
              DispatchQueue.main.asyncAfter(wallDeadline: .now()) {
                self.dispatch(NavigationAction.completeRouting(scene: self.routeInfo.sceneName))
              }
            }
          }
      } else {
        content
      }
    }
  }

  func createRoute() -> StackRoute {
    StackRoute(
      path: routeInfo.path,
      view: branchView()
    )
  }
}

extension View {

  func addStackRoute<V>(@ViewBuilder branchView: @escaping () -> V) -> some View where V: View {
    StackRouteBuilder(content: self, branchView: branchView)
  }
}
