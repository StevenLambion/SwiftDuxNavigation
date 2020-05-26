#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct NativeStackNavigationView<RootView>: View where RootView: View {
    @Environment(\.waypoint) private var waypoint
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent
    @MappedDispatch() private var dispatch

    var animate: Bool
    var rootView: RootView

    var body: some View {
      rootView
    }
  }

#endif
