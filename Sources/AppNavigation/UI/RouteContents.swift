import SwiftDux
import SwiftUI

/// Place above the contents of a route.
///
/// This handles any house keeping required to properly manage the route state
/// within the view layer.
public struct RouteContents<Content>: View where Content: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  private var route: RouteState
  private var content: Content

  private var isLastRoute: Bool {
    routeInfo.path == route.lastLeg.parentPath
  }

  /// Initiate a new RouteContents.
  /// - Parameters:
  ///   - route: The route itself.
  ///   - content: The contents of the route.
  init(route: RouteState, @ViewBuilder content: () -> Content) {
    self.route = route
    self.content = content()
  }

  public struct Props: Equatable {
    var completed: Bool
    var isLastRoute: Bool
  }

  public var body: some View {
    if !self.route.completed && self.isLastRoute {
      self.dispatch(NavigationAction.completeRouting(scene: self.routeInfo.sceneName))
    }
    return content
  }
}
