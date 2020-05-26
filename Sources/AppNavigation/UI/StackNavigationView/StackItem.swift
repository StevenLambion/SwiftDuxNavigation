import SwiftUI

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

  /// Add a new stack waypoint that accepts a path parameter.
  ///
  /// - Parameters:
  ///   - name: The name of the stack item.
  ///   - content: The view of the waypoint.
  /// - Returns: A view.
  public func stackItem<T, Content>(_ name: String? = nil, @ViewBuilder content: @escaping (T) -> Content) -> some View
  where T: LosslessStringConvertible & Equatable, Content: View {
    self.modifier(DynamicStackItemViewModifier(name: name, stackItemContent: content))
  }
}
