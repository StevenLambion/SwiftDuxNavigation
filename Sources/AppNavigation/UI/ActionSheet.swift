import SwiftDux
import SwiftUI

extension View {

  /// Create a waypoint that displays an action sheet.
  ///
  /// - Parameters:
  ///   - type: The type of waypoint.
  ///   - content: The action sheet to display.
  /// - Returns: A view.
  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  @available(OSX, unavailable)
  public func actionSheet(_ type: WaypointType, content: @escaping () -> ActionSheet) -> some View {
    WaypointView(type) { waypoint in
      actionSheet(isPresented: waypoint.$isActive, content: content)
    }
  }
}
