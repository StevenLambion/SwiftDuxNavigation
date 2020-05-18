import Dispatch
import SwiftDux
import SwiftUI

/// Button that navigates to  a route.
public struct RouteLink<Label>: View where Label: View {
  @Environment(\.currentRoute) private var currentRoute
  @MappedDispatch() private var dispatch

  private var path: String
  private var scene: String?
  private var isDetail: Bool
  private var animate: Bool
  private var label: () -> Label

  // swift-format-ignore: ValidateDocumentationComments

  /// Initiate a new `RouteLink`
  /// - Parameters:
  ///   - path: The path to navigate to. It may be a relative or absolute path.
  ///   - animate: Animate the navigation.
  ///   - label: The label of the button.
  public init<T>(path: T, scene: String? = nil, isDetail: Bool = false, animate: Bool = true, @ViewBuilder label: @escaping () -> Label)
  where T: LosslessStringConvertible {
    self.path = String(path)
    self.scene = scene
    self.isDetail = isDetail
    self.animate = animate
    self.label = label
  }

  public var body: some View {
    Button(action: self.navigate, label: label)
  }

  private func navigate() {
    DispatchQueue.main.async {
      self.dispatch(self.currentRoute.navigate(to: self.path, inScene: self.scene, isDetail: self.isDetail, animate: self.animate))
    }
  }
}
