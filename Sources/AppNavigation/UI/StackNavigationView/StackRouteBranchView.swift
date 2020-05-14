import SwiftDux
import SwiftUI

public struct StackRouteBranchView<Content>: View where Content: View {
  @MappedDispatch() private var dispatch

  private var content: Content
  private var name: String
  private var isDefault: Bool

  init(content: Content, name: String, isDefault: Bool) {
    self.content = content
    self.name = name
    self.isDefault = isDefault
  }

  public var body: some View {
    RouteContents(content: routeContents)
  }

  private func routeContents(routeInfo: RouteInfo, leg: RouteLeg?, route: RouteState) -> some View {
    let shouldRedirect = isDefault && route.path == routeInfo.path
    let isActive = leg?.component == name && !shouldRedirect
    return Redirect(path: name, enabled: shouldRedirect) {
      if isActive {
        self.content.environment(\.routeInfo, routeInfo.next(with: name, isBranch: true))
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
    StackRouteBranchView(content: self, name: name, isDefault: isDefault)
  }
}
