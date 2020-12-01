import SwiftDux
import SwiftUI

extension View {

  /// Create a waypoint that displays an alert.
  ///
  /// - Parameters:
  ///   - type: The type of waypoint.
  ///   - content: The alert to display.
  /// - Returns: A view.
  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  @available(OSX, unavailable)
  public func alert(_ type: WaypointType, content: @escaping () -> Alert) -> some View {
    WaypointView(type) { info in
      alert(isPresented: info.$isActive, content: content)
    }
  }
}
