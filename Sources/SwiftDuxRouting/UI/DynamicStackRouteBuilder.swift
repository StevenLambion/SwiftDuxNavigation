import Dispatch
import SwiftDux
import SwiftUI

public struct DynamicStackRouteBuilder<Content, T, BranchView>: ConnectableView
where Content: View, T: LosslessStringConvertible & Equatable, BranchView: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  internal var content: Content
  internal var branchView: (T) -> BranchView

  @State private var childRoutes: [StackRoute] = []

  public struct Props: Equatable {
    var pathParam: T?
    var completed: Bool
    var isLastRoute: Bool
  }

  public func map(state: NavigationStateRoot, binder: ActionBinder) -> Props? {
    let route = routeInfo.resolve(in: state)
    let segment = route?.legsByPath[routeInfo.path]
    return Props(
      pathParam: segment.flatMap { !$0.component.isEmpty ? T($0.component) : nil },
      completed: route?.completed ?? true,
      isLastRoute: routeInfo.path == route?.lastLeg.parentPath
    )
  }

  public func body(props: Props) -> some View {
    return Group {
      if props.pathParam != nil {
        content
          .preference(
            key: StackRoutePreferenceKey.self,
            value: [createRoute(pathParam: props.pathParam!)] + childRoutes
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

  private func createRoute(pathParam: T) -> StackRoute {
    let nextRouteInfo = routeInfo.next(with: pathParam)
    return StackRoute(
      path: nextRouteInfo.path,
      fromBranch: routeInfo.isBranch,
      view: branchView(pathParam)
        .environment(\.routeInfo, nextRouteInfo)
        .onPreferenceChange(StackRoutePreferenceKey.self) {
          self.childRoutes = $0
        }
    )
  }
}

extension View {

  public func addStackRoute<T, V>(@ViewBuilder branchView: @escaping (T) -> V) -> some View
  where T: LosslessStringConvertible & Equatable, V: View {
    DynamicStackRouteBuilder(content: self, branchView: branchView)
  }
}
