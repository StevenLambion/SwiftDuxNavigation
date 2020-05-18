import SwiftDux
import SwiftUI

internal struct StackRouteBranchViewModifier: ViewModifier {
  var name: String
  var isDefault: Bool

  func body(content: Content) -> some View {
    RouteContents { currentRoute, leg, route in
      self.routeContents(content: content, currentRoute: currentRoute, leg: leg, route: route)
    }
  }

  private func routeContents(content: Content, currentRoute: CurrentRoute, leg: RouteLeg?, route: RouteState) -> some View {
    let shouldRedirect = isDefault && route.path == currentRoute.path
    let isActive = leg?.component == name && !shouldRedirect
    let nextRoute = currentRoute.next(with: name, isBranch: true)
    return Redirect(path: name, enabled: shouldRedirect) {
      if isActive {
        content.id(nextRoute.path).environment(\.currentRoute, nextRoute)
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
