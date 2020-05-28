#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemViewModifier<StackItemContent> where StackItemContent: View {
    var name: String?
    var stackItemContent: StackItemContent

    @State private var childPreference = StackNavigationPreference()

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      StackItemCard(stackItem: createStackItem(info: info), childPreference: childPreference, animate: info.animate, content: content)
    }

    private func createStackItem(info: ResolvedWaypointInfo) -> StackItem {
      let waypoint = info.nextWaypoint
      return StackItem(
        path: waypoint.path,
        view:
          stackItemContent
          .waypoint(with: waypoint)
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.childPreference = $0
          }
      )
    }
  }

  extension StackItemViewModifier: WaypointResolverViewModifier {}
#endif
