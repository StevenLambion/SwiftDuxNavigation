#if canImport(UIKit)

  import SwiftUI

  internal struct StackNavigationPreference: Equatable {
    var stack: [StackItem] = []
    var animate: Bool = false
    var options: StackNavigationOptions = StackNavigationOptions()

    /// When going from one view hierarchy to another, we need to merge two preferences together.
    /// Keeping the transformer around simplifies the merging of options.
    var optionTransformers: [(inout StackNavigationOptions) -> Void] = []

    static func == (lhs: StackNavigationPreference, rhs: StackNavigationPreference) -> Bool {
      lhs.stack == rhs.stack && lhs.animate == rhs.animate && lhs.options == rhs.options
    }
  }

  internal final class StackNavigationPreferenceKey: PreferenceKey {
    static var defaultValue = StackNavigationPreference()

    static func reduce(value: inout StackNavigationPreference, nextValue: () -> StackNavigationPreference) {
    }
  }

  extension View {

    internal func stackNavigationPreference(_ updater: @escaping (inout StackNavigationPreference) -> Void) -> some View {
      transformPreference(StackNavigationPreferenceKey.self, updater)
    }
  }

#endif
