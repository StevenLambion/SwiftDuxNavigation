import SwiftDux
import SwiftUI

/// Starts a new Route with a given name.
public struct Route<Content>: View where Content: View {
  @Environment(\.actionDispatcher) private var dispatch

  public var name: String
  public var content: Content

  /// Initiate a Route with a name.
  ///
  /// - Parameters:
  ///   - name: The name of the route.
  ///   - content: A closure that returns the content of the waypoint.
  public init(name: String, @ViewBuilder content: () -> Content) {
    self.name = name
    self.content = content()
  }

  public var body: some View {
    let waypoint = Waypoint(
      routeName: name,
      path: "/",
      isDetail: false,
      isActive: Binding(get: { true }, set: { _ in }),
      destination: .constant("")
    )
    return
      content
      .environment(\.waypoint, waypoint)
      .transformPreference(VerifiedPathPreferenceKey.self) { preference in
        if preference.primaryPath.isEmpty {
          preference.primaryPath = "/"
        }
      }
      .onPreferenceChange(VerifiedPathPreferenceKey.self) { preference in
        let primaryPath = preference.primaryPath
        let detailPath = preference.detailPath
        dispatch(NavigationAction.verifyRoutePaths(primaryPath: primaryPath, detailPath: detailPath, routeName: name))
      }
  }
}
