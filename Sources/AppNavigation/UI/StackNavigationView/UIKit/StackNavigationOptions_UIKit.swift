#if canImport(UIKit)

  import SwiftUI

  internal struct StackNavigationOptions: Equatable {
    var swipeGesture: Bool = true
    var hideBarsOnTap: Bool = false
    var hideBarsOnSwipe: Bool = false
    var hidesBarsWhenVerticallyCompact: Bool = false
    var hidesBarsWhenKeyboardAppears: Bool = false
    var barTintColor: UIColor? = nil
    var showSplitViewDisplayModeButton: Bool = false
  }

  internal final class StackNavigationPreferenceKey: PreferenceKey {
    static var defaultValue = StackNavigationOptions()

    static func reduce(value: inout StackNavigationOptions, nextValue: () -> StackNavigationOptions) {
      value = nextValue()
    }
  }

  extension View {

    internal func stackNavigationPreference(_ updater: @escaping (inout StackNavigationOptions) -> Void) -> some View {
      self.transformPreference(StackNavigationPreferenceKey.self, updater)
    }

    /// Navigate back in a stack navigation view using a swipe gesture.
    ///
    /// - Parameter enabled: Is enabled
    /// - Returns: The view.
    public func enableSwipeNavigation(_ enabled: Bool) -> some View {
      self.stackNavigationPreference { $0.swipeGesture = enabled }
    }

    /// Hide the navigation bar conditionally.
    /// 
    /// - Parameters:
    ///   - onTap: When the user taps the view.
    ///   - onSwipe: When the user swipes in the view.
    ///   - onVerticallyCompact: When the view is vertically compact.
    ///   - onKeyboardAppears: When the keyboard appears.
    /// - Returns: The view.
    public func hideNavigationBar(onTap: Bool = false, onSwipe: Bool = false, onVerticallyCompact: Bool = false, onKeyboardAppears: Bool = false) -> some View {
      self.stackNavigationPreference {
        $0.hideBarsOnTap = onTap
        $0.hideBarsOnSwipe = onSwipe
        $0.hidesBarsWhenVerticallyCompact = onVerticallyCompact
        $0.hidesBarsWhenKeyboardAppears = onKeyboardAppears
      }
    }

    /// Set the tint color of the navigation bar.
    ///
    /// - Parameter color: The tint color.
    /// - Returns: The view.
    public func stackNavigationBarTintColor(_ color: UIColor) -> some View {
      self.stackNavigationPreference {
        $0.barTintColor = color
      }
    }

    /// Display the split view display mode if it's available.
    ///.
    /// - Parameter enabled: enable to replace the root view.
    /// - Returns: The view.
    public func showSplitViewDisplayModeButton(_ enabled: Bool) -> some View {
      self.stackNavigationPreference {
        $0.showSplitViewDisplayModeButton = enabled
      }
    }
  }

#endif
