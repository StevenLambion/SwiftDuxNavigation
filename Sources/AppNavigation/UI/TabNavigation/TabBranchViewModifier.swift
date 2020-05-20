import SwiftDux
import SwiftUI

internal struct TabBranchViewModifier: ViewModifier {
  @Environment(\.store) private var anyStore

  var name: String

  func body(content: Content) -> some View {
    content.provideStore(anyStore)
  }
}

extension View {
  public func tabBranch<Label>(_ name: String, @ViewBuilder label: () -> Label) -> some View where Label: View {
    self.tabItem(label).tag(name)
  }
}
