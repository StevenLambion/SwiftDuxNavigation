import SwiftDux
import SwiftUI

internal struct StackRouteBranchViewModifier: ViewModifier {
  @Environment(\.store) private var anyStore
  @MappedDispatch() private var dispatch

  var name: String
  var isDefault: Bool = false

  func body(content: Content) -> some View {
    RouteContents { self.routeContents(content: content, routeInfo: $0) }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo) -> some View {
    let isActive = routeInfo.pathParameter == name
    let shouldRedirect = !isActive && isDefault && routeInfo.fullPath == routeInfo.current.path
    let nextRoute = routeInfo.current.next(with: name, isBranch: true)
    if shouldRedirect {
      dispatch(routeInfo.current.navigate(to: name, animate: false))
    }
    return Group {
      if isActive {
        content.provideStore(anyStore).id(nextRoute.path).environment(\.currentRoute, nextRoute)
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
