#if os(macOS)
  import SwiftUI

  internal struct NativeSplitNavigationView<MasterContent>: View where MasterContent: View {
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent

    var masterContent: MasterContent

    var body: some View {
      HSplitView {
        self.masterView()
        self.detailView()
      }
      .clearDetailItem()
    }

    private func masterView() -> some View {
      StackNavigationView {
        self.masterContent
      }
      .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
    }

    private func detailView() -> some View {
      StackNavigationView {
        self.rootDetailWaypointContent?.view
          .waypoint(with: self.rootDetailWaypointContent?.waypoint)
      }
      .frame(maxWidth: .infinity)
      .layoutPriority(1)
    }
  }

#endif
