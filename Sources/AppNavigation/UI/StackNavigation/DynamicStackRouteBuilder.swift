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
    var route: RouteState
    var pathParam: T?
  }

  public func map(state: NavigationStateRoot, binder: ActionBinder) -> Props? {
    guard let route = routeInfo.resolve(in: state) else { return nil }
    let leg = route.legsByPath[routeInfo.path]
    return Props(
      route: route,
      pathParam: leg.flatMap { !$0.component.isEmpty ? T($0.component) : nil }
    )
  }

  public func body(props: Props) -> some View {
    RouteContents(route: props.route) {
      if props.pathParam != nil {
        content.stackRoutePreference([createRoute(pathParam: props.pathParam!)] + childRoutes)
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