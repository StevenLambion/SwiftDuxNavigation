#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemViewModifier<StackItemContent>: WaypointResolverViewModifier where StackItemContent: View {
    var name: String?
    var stackItemContent: StackItemContent

    @State private var childStackItems: [StackItem] = []
    @State private var stackNavigationOptions: StackNavigationOptions = StackNavigationOptions()

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      Group {
        if info.active {
          content
            .onPreferenceChange(StackItemPreferenceKey.self) {
              self.childStackItems = $0
            }
            .onPreferenceChange(StackNavigationPreferenceKey.self) {
              self.stackNavigationOptions = $0
            }
            .stackItemPreference(createStackItem(from: info))
            .stackNavigationPreference { $0 = self.stackNavigationOptions }
        } else {
          content
        }
      }
    }

    private func createStackItem(from info: ResolvedWaypointInfo) -> [StackItem] {
      let waypoint = info.waypoint
      var stackItems = childStackItems
      let newStackItem = StackItem(
        path: waypoint.path,
        view:
          stackItemContent
          .waypoint(with: info.nextWaypoint)
          .onPreferenceChange(StackItemPreferenceKey.self) {
            self.childStackItems = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
      )
      stackItems.append(newStackItem)
      return stackItems
    }
  }

  extension View {

    /// Add a new stack waypoint.
    /// 
    /// - Parameters:
    ///   - name: The name of the stack item.
    ///   - content: The view of the waypoint.
    /// - Returns: A view.
    public func stackItem<Content>(_ name: String? = nil, @ViewBuilder content: () -> Content) -> some View where Content: View {
      self.modifier(StackItemViewModifier(name: name, stackItemContent: content()))
    }
  }

#endif
