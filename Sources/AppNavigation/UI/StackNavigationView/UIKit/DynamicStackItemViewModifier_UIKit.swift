#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackItemViewModifier<T, StackItemContent> where T: LosslessStringConvertible & Equatable, StackItemContent: View {
    var name: String?
    var stackItemContent: (T) -> StackItemContent

    @State private var childPreference = StackNavigationPreference()

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      StackItemCard(stackItem: createStackItem(info: info), childPreference: childPreference, animate: info.animate, content: content)
    }

    private func createStackItem(info: ResolvedWaypointInfo) -> StackItem? {
      guard
        info.active,
        let pathParameter = info.pathParameter(as: T.self)
      else {
        return nil
      }
      let waypoint = info.nextWaypoint
      return StackItem(
        path: waypoint.path,
        view: stackItemContent(pathParameter)
          .waypoint(with: waypoint)
          .onPreferenceChange(StackNavigationPreferenceKey.self) {
            self.childPreference = $0
          }
      )
    }
  }

  extension DynamicStackItemViewModifier: WaypointResolverViewModifier {
    static var hasPathParameter: Bool { true }
  }

#endif
