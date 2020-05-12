import SwiftUI

internal struct StackRoutePreferenceKey: PreferenceKey {
  static var defaultValue: [StackRoute] = []

  static func reduce(value: inout [StackRoute], nextValue: () -> [StackRoute]) {
    value = nextValue()
  }
}
