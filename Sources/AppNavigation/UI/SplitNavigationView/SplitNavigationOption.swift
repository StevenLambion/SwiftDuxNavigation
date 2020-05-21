#if canImport(UIKIt)

  import SwiftUI
  import SwiftDux

  internal enum SplitNavigationOption: Hashable {
    case showDisplayModeButton(Bool)
    case preferredDisplayMode(UISplitViewController.DisplayMode)
    case primaryEdge(UISplitViewController.PrimaryEdge)
    case presentsWithGesture(Bool)
    case preferredPrimaryColumnWidthFraction(CGFloat)
    case primaryBackgroundStyle(UISplitViewController.BackgroundStyle)

    static var defaultOptions: Set<SplitNavigationOption> {
      Set<SplitNavigationOption>([
        .showDisplayModeButton(true),
        .preferredDisplayMode(.allVisible),
        .primaryEdge(.leading),
        .presentsWithGesture(true),
        .preferredPrimaryColumnWidthFraction(UISplitViewController.automaticDimension),
        .primaryBackgroundStyle(.none),
      ])
    }
  }

  internal final class SplitNavigationEnvironmentKey: EnvironmentKey {
    static var defaultValue = SplitNavigationOption.defaultOptions
  }

  extension EnvironmentValues {

    internal var splitNavigationOptions: Set<SplitNavigationOption> {
      get { self[SplitNavigationEnvironmentKey] }
      set { self[SplitNavigationEnvironmentKey] = newValue }
    }
  }

  extension View {

    internal func setSplitNavigationOption(_ preference: Set<SplitNavigationOption>) -> some View {
      self.transformEnvironment(\.splitNavigationOptions) { $0 = $0.union(preference) }
    }

    /// Show the display mode button.
    ///
    /// - Parameter enabled: show the button.
    /// - Returns: The view.
    public func splitNavigationShowDisplayModeButton(_ enabled: Bool) -> some View {
      self.setSplitNavigationOption([.showDisplayModeButton(enabled)])
    }

    /// Set the preferred display mode.
    ///
    /// - Parameter displayMode: The display mode.
    /// - Returns: The view.
    public func splitNavigationPreferredDisplayMode(_ displayMode: UISplitViewController.DisplayMode) -> some View {
      self.setSplitNavigationOption([.preferredDisplayMode(displayMode)])
    }

    /// Present the primary panel with a swipe gesture.
    ///
    /// - Parameter enabled: Enable the gesture.
    /// - Returns: The view.
    public func splitNavigationPresentsWithGesture(_ enabled: Bool) -> some View {
      self.setSplitNavigationOption([.presentsWithGesture(enabled)])
    }

    // swift-format-ignore: ValidateDocumentationComments

    /// Set the preferred column width fraction of the primary panel
    ///
    /// - Parameter value: The column width fraction.
    /// - Returns: The view.
    public func splitNavigationPreferredPrimaryColumnWidthFraction(_ value: CGFloat) -> some View {
      self.setSplitNavigationOption([.preferredPrimaryColumnWidthFraction(value)])
    }

    /// Set the edge location of the primary panel.
    ///
    /// - Parameter value: The edge to display the panel.
    /// - Returns: The view.
    public func splitNavigationPrimaryEdge(_ value: UISplitViewController.PrimaryEdge) -> some View {
      self.setSplitNavigationOption([.primaryEdge(value)])
    }

    /// Set background style of the primary panel.
    /// 
    /// - Parameter value: The background style.
    /// - Returns: The view.
    public func splitNavigationPrimaryBackgroundStyle(_ value: UISplitViewController.BackgroundStyle) -> some View {
      self.setSplitNavigationOption([.primaryBackgroundStyle(value)])
    }
  }

#endif
