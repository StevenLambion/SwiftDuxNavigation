import SwiftDux
import SwiftUI

/// Conditionally redirects to a path if it's not currently on the active route.
///
/// This is useful if there isn't a proper view for the current route path or the route
/// becomes invalid for the use case.
public struct Redirect<Content>: View where Content: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  private var path: String
  private var animate: Bool
  private var enabled: Bool
  private var content: Content

  /// Initiate a new Redirect.
  /// - Parameters:
  ///   - path: The path to redirect to. It may be relative or absolute.
  ///   - animate: Animate the redirect if possible.
  ///   - enabled: Enables the redirect. Defaults to true.
  ///   - content: The content to display if it should not redirect.
  init(path: String, animate: Bool = false, enabled: Bool = true, @ViewBuilder content: () -> Content) {
    self.path = path
    self.animate = animate
    self.enabled = enabled
    self.content = content()
  }

  public var body: some View {
    content.onAppear {
      guard self.enabled else { return }
      guard let absolutePath = self.path.standardizePath(withBasePath: self.routeInfo.path) else { return }
      if !self.routeInfo.path.starts(with: absolutePath) {
        self.dispatch(NavigationAction.navigate(to: absolutePath, in: self.routeInfo.sceneName, animate: self.animate))
      }
    }
  }
}
