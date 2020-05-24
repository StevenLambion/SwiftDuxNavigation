#if canImport(UIKit)

  import SwiftUI

  internal final class StackItemPreferenceKey: PreferenceKey {
    static var defaultValue: [StackItem] = []

    static func reduce(value: inout [StackItem], nextValue: () -> [StackItem]) {
      value = nextValue()
    }
  }

  extension View {

    internal func stackItemPreference(_ stackItems: [StackItem]) -> some View {
      self.transformPreference(StackItemPreferenceKey.self) {
        $0 += stackItems
      }
    }
  }

#endif
