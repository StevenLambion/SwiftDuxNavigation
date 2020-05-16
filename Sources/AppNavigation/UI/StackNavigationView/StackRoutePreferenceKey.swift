import SwiftUI

internal final class StackRoutePreferenceKey: PreferenceKey {
  static var defaultValue: [StackRoute] = []

  static func reduce(value: inout [StackRoute], nextValue: () -> [StackRoute]) {
    value = nextValue()
  }
}

extension View {

  func stackRoutePreference(_ routes: [StackRoute]) -> some View {
    self.preference(key: StackRoutePreferenceKey.self, value: routes)
  }
}
