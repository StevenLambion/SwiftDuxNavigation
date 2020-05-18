#if canImport(UIKit)

  import SwiftUI

  internal enum StackNavigationOption: Hashable {
    case swipeGesture(Bool)
    case hideBarsOnTap(Bool)
    case hideBarsOnSwipe(Bool)
    case hidesBarsWhenVerticallyCompact(Bool)
    case hidesBarsWhenKeyboardAppears(Bool)
    case barTintColor(UIColor?)
    case replaceRoot(Bool)

    static var defaultOptions: Set<StackNavigationOption> = Set([
      .swipeGesture(true),
      .hideBarsOnTap(false),
      .hideBarsOnSwipe(false),
      .hidesBarsWhenVerticallyCompact(false),
      .hidesBarsWhenKeyboardAppears(false),
      .barTintColor(nil),
      .replaceRoot(false),
    ])
  }

  internal final class StackNavigationPreferenceKey: PreferenceKey {
    static var defaultValue = StackNavigationOption.defaultOptions

    static func reduce(value: inout Set<StackNavigationOption>, nextValue: () -> Set<StackNavigationOption>) {
      value = value.union(nextValue())
    }
  }

  extension View {

    internal func stackNavigationPreference(_ preference: Set<StackNavigationOption>) -> some View {
      self.preference(key: StackNavigationPreferenceKey.self, value: preference)
    }

    /// Navigate back in a stack navigation view using a swipe gesture.
    /// - Parameter enabled: Is enabled
    /// - Returns: The view.
    public func enableSwipeNavigation(_ enabled: Bool) -> some View {
      self.stackNavigationPreference([.swipeGesture(enabled)])
    }

    /// Hide the navigation bar conditionally.
    /// - Parameters:
    ///   - onTap: When the user taps the view.
    ///   - onSwipe: When the user swipes in the view.
    ///   - onVerticallyCompact: When the view is vertically compact.
    ///   - onKeyboardAppears: When the keyboard appears.
    /// - Returns: The view.
    public func hideNavigationBar(onTap: Bool = false, onSwipe: Bool = false, onVerticallyCompact: Bool = false, onKeyboardAppears: Bool = false) -> some View {
      self.stackNavigationPreference([
        .hideBarsOnTap(onTap),
        .hideBarsOnSwipe(onSwipe),
        .hidesBarsWhenVerticallyCompact(onVerticallyCompact),
        .hidesBarsWhenKeyboardAppears(onKeyboardAppears),
      ])
    }

    public func stackNavigationBarTintColor(_ color: UIColor) -> some View {
      self.stackNavigationPreference([.barTintColor(color)])
    }

    public func stackNavigationReplaceRoot(_ enabled: Bool) -> some View {
      self.stackNavigationPreference([.replaceRoot(enabled)])
    }
  }

#endif
