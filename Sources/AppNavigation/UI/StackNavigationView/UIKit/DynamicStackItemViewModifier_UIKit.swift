#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackItemViewModifier<T, StackItemContent>: WaypointResolverViewModifier
  where T: LosslessStringConvertible & Equatable, StackItemContent: View {
    static var hasPathParameter: Bool {
      true
    }

    var name: String?
    var stackItemContent: (T) -> StackItemContent

    @State private var childStackItems: [StackItem] = []
    @State private var stackNavigationOptions: StackNavigationOptions? = nil

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      content
        .stackItemPreference(info.active ? createStackItem(info: info) : childStackItems)
        .stackNavigationPreference {
          guard let options = self.stackNavigationOptions else { return }
          $0 = options
        }
    }

    private func createStackItem(info: ResolvedWaypointInfo) -> [StackItem] {
      var stackItems = childStackItems
      guard let pathParameter = info.pathParameter(as: T.self) else {
        return stackItems
      }
      let waypoint = info.nextWaypoint
      let newStackItem = StackItem(
        path: waypoint.path,
        fromBranch: false,
        view: stackItemContent(pathParameter)
          .waypoint(with: waypoint)
          .onPreferenceChange(StackItemPreferenceKey.self) {
            self.childStackItems = $0
          }
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.stackNavigationOptions = $0
          }
      )

      stackItems.insert(newStackItem, at: 0)
      return stackItems
    }
  }

#endif
