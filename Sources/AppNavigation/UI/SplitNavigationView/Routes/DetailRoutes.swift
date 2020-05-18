import SwiftDux
import SwiftUI

internal final class DetailRoutesKey: EnvironmentKey {
  public static var defaultValue: [String: AnyView] = [:]
}

extension EnvironmentValues {

  internal var detailRoutes: [String: AnyView] {
    get { self[DetailRoutesKey] }
    set { self[DetailRoutesKey] = newValue }
  }
}
