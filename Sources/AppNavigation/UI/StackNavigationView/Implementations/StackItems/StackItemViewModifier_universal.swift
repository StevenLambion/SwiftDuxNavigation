#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemViewModifier<StackItemContent>: WaypointResolverViewModifier where StackItemContent: View {
    var name: String?
    var stackItemContent: StackItemContent

    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      ZStack {
        if !info.active {
          content.zIndex(0)
        }
        Group {
          if info.active {
            StackItemCard {
              stackItemContent.waypoint(with: info.nextWaypoint)
            }
          }
        }
        .zIndex(1)
        .transition(transition(forActive: info.active))
      }
      .animation(info.animate ? .easeOut : .none)
    }

    private func transition(forActive active: Bool) -> AnyTransition {
      active
        ? AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        : AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }
  }
#endif
