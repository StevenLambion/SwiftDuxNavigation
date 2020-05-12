import SwiftDux
import SwiftUI

/// Button that navigates to  a route.
public struct RouteLink<Label>: View where Label: View {
  @Environment(\.routeInfo) private var routeInfo
  @MappedDispatch() private var dispatch

  private var path: String
  private var animate: Bool
  private var label: () -> Label

  // swift-format-ignore: ValidateDocumentationComments

  /// Initiate a new `RouteLink`
  /// - Parameters:
  ///   - path: The path to navigate to. It may be a relative or absolute path.
  ///   - animate: Animate the navigation.
  ///   - label: The label of the button.
  public init<T>(path: T, animate: Bool = true, @ViewBuilder label: @escaping () -> Label) where T: LosslessStringConvertible {
    self.path = String(path)
    self.animate = animate
    self.label = label
  }

  public var body: some View {
    Button(action: self.navigate, label: label)
  }

  private func navigate() {
    dispatch(NavigationAction.navigate(to: path, in: routeInfo.sceneName, animate: animate))
  }
}
