#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct DynamicStackItemViewModifier<T, StackItemContent>: WaypointResolverViewModifier
  where T: LosslessStringConvertible & Equatable, StackItemContent: View {
    static var hasPathParameter: Bool {
      true
    }

    var name: String?
    var stackItemContent: (T) -> StackItemContent
    
    public func body(content: Content, info: ResolvedWaypointInfo) -> some View {
      ZStack {
        content.zIndex(0)
        contentCard(content: content, info: info)
          .transition(transition(forActive: info.active))
          .animation(info.animate ? .easeOut : .none)
      }
    }
    
    private func contentCard(content: Content, info: ResolvedWaypointInfo) -> some View {
      let pathParameter = info.pathParameter(as: T.self)
      return Group {
        if pathParameter != nil && info.active {
          VStack {
            Spacer()
            stackItemContent(pathParameter!).waypoint(with: info.nextWaypoint)
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
