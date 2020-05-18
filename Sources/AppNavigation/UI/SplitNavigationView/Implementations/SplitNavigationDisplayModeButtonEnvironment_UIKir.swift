#if canImport(UIKit)

  import SwiftUI
  import SwiftDux

  internal final class SplitNavigationDisplayModeButtonKey: EnvironmentKey {
    public static var defaultValue: UIBarButtonItem? = nil
  }

  extension EnvironmentValues {

    internal var splitNavigationDisplayModeButton: UIBarButtonItem? {
      get { self[SplitNavigationDisplayModeButtonKey] }
      set { self[SplitNavigationDisplayModeButtonKey] = newValue }
    }
  }

#endif
