import SwiftDux
import SwiftUI

internal struct StackRouteBranchViewModifier: RouteReaderViewModifier {
  @Environment(\.store) private var anyStore
  @MappedDispatch() private var dispatch

  var name: String
  var isDefault: Bool = false

  public func body(content: Content, routeInfo: RouteInfo) -> some View {
    let isActive = routeInfo.pathParameter == name
    let shouldRedirect = !isActive && isDefault && routeInfo.path == routeInfo.waypoint.path
    if shouldRedirect {
      dispatch(routeInfo.waypoint.navigate(to: name, animate: false))
    }
    return Group {
      if isActive {
        content.provideStore(anyStore).id(routeInfo.waypoint.path + routeInfo.pathParameter!).nextWaypoint(with: name, isBranch: true)
      }
    }
  }
}

extension View {

  /// Specify a new branch at the root of a route.
  /// - Parameters:
  ///   - name: The name of the branch
  ///   - isDefault: Redirect to this branch if no branch is active.
  /// - Returns: A view.
  public func branch(_ name: String, isDefault: Bool = false) -> some View {
    self.tag(name).modifier(StackRouteBranchViewModifier(name: name, isDefault: isDefault))
  }
}
