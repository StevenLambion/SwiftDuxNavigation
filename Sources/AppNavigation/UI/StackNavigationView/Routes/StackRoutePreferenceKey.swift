#if canImport(UIKit)

  import SwiftUI

  internal struct StackRouteStorage: Equatable {
    var master: [StackRoute] = []
    var detail: [StackRoute] = []

    var all: [StackRoute] {
      master + detail
    }

    static func + (lhs: StackRouteStorage, rhs: StackRouteStorage) -> StackRouteStorage {
      StackRouteStorage(
        master: lhs.master + rhs.master,
        detail: lhs.detail + rhs.detail
      )
    }
  }

  internal final class StackRoutePreferenceKey: PreferenceKey {
    static var defaultValue: StackRouteStorage = StackRouteStorage()

    static func reduce(value: inout StackRouteStorage, nextValue: () -> StackRouteStorage) {
      value = nextValue()
    }
  }

  extension View {

    func stackRoutePreference(_ routes: StackRouteStorage) -> some View {
      self.preference(key: StackRoutePreferenceKey.self, value: routes)
    }
  }

#endif
