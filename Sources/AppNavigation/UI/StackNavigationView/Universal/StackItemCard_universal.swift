#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemCard<Content>: View where Content: View {
    var content: Content

    private var spacer: Spacer {
      Spacer(minLength: 0)
    }

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      VStack(spacing: 0) {
        spacer
        content
        spacer
      }
    }
  }
#endif
