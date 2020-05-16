import SwiftDux
import SwiftUI

public struct StackRouteBranchViewModifier: ViewModifier {
  @MappedDispatch() private var dispatch

  var name: String
  var isDefault: Bool

  public func body(content: Content) -> some View {
    RouteContents { routeInfo, leg, route in
      self.routeContents(content: content, routeInfo: routeInfo, leg: leg, route: route)
    }
  }

  private func routeContents(content: Content, routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    let shouldRedirect = isDefault && route.path == routeInfo.path
    let isActive = leg?.component == name && !shouldRedirect
    return Redirect(path: name, enabled: shouldRedirect) {
      if isActive {
        content.environment(\.routeInfo, routeInfo.next(with: name, isBranch: true))
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
    self.modifier(StackRouteBranchViewModifier(name: name, isDefault: isDefault))
  }
}
