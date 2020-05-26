#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemViewModifier<StackItemContent>: WaypointResolverViewModifier where StackItemContent: View {
    var name: String?
    var stackItemContent: StackItemContent

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      ZStack {
        content.zIndex(0)
        contentCard(content: content, info: info)
          .transition(transition(forActive: info.active))
          .animation(info.animate ? .easeOut : .none)
      }
    }

    private func contentCard(content: Content, info: ResolvedWaypointInfo) -> some View {
      return Group {
        if info.active {
          VStack {
            Spacer()
            stackItemContent.waypoint(with: info.nextWaypoint)
            Spacer()
          }
          .background(Color.white)
          .zIndex(1)
        }
      }
    }

    private func transition(forActive active: Bool) -> AnyTransition {
      active
        ? AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        : AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }
  }
#endif
