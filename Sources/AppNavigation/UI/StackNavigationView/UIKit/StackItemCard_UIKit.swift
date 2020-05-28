#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItemCard<Content>: View where Content: View {
    var stackItem: StackItem?
    var childPreference: StackNavigationPreference
    var animate: Bool
    var content: Content

    public var body: some View {
      content.stackNavigationPreference { [childPreference, stackItem, animate] preference in
        if let stackItem = stackItem {
          preference.stack.append(stackItem)
          preference.animate = childPreference.animate || animate || preference.animate
        }
        preference.stack += childPreference.stack
        childPreference.optionTransformers.forEach { updater in updater(&preference.options) }
        preference.optionTransformers += childPreference.optionTransformers
      }
    }
  }

#endif
