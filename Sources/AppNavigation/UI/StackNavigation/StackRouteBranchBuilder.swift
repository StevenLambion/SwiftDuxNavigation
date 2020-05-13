import SwiftDux
import SwiftUI

public struct StackRouteBranchBuilder<Content>: ConnectableView where Content: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  private var content: Content
  private var name: String
  private var isDefault: Bool

  init(content: Content, name: String, isDefault: Bool) {
    self.content = content
    self.name = name
    self.isDefault = isDefault
  }

  public struct Props: Equatable {
    var route: RouteState
    var isActive: Bool
    var shouldRedirect: Bool
  }

  public func map(state: NavigationStateRoot, binder: ActionBinder) -> Props? {
    guard let route = routeInfo.resolve(in: state) else { return nil }
    let shouldRedirect = isDefault && route.path == routeInfo.path
    let leg = routeInfo.resolveLeg(in: state)
    return Props(
      route: route,
      isActive: leg?.component == name && !shouldRedirect,
      shouldRedirect: shouldRedirect
    )
  }

  public func body(props: Props) -> some View {
    Redirect(path: name, enabled: props.shouldRedirect) {
      RouteContents(route: props.route) {
        if props.isActive {
          content.environment(\.routeInfo, routeInfo.next(with: name, isBranch: true))
        }
      }
    }
  }
}

extension View {

  public func branch(_ name: String, isDefault: Bool = false) -> some View {
    StackRouteBranchBuilder(content: self, name: name, isDefault: isDefault)
  }
}
