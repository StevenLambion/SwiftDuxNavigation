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
  
  /// Add a tab to a TabNavigationView.
  ///
  /// - Parameters:
  ///   - name: The name of the route branch for the tab.
  ///   - label: A label to display as the tab.
  /// - Returns: The view.
  public func tabBranch<Label>(_ name: String, @ViewBuilder label: () -> Label) -> some View where Label: View {
    self.tabItem(label).tag(name)
  }
}
