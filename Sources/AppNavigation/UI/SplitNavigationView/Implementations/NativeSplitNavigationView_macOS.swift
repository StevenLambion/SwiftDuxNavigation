#if os(macOS)

  import SwiftDux
  import SwiftUI

  internal struct NativeSplitNavigationView<MasterContent>: View where MasterContent: View {
    @Environment(\.rootDetailWaypointContent) private var rootDetailWaypointContent

    var masterContent: MasterContent

    var body: some View {
      GeometryReader { geometry in
        HSplitView {
          self.masterView(geometry: geometry)
          self.detailView(geometry: geometry)
        }.frame(width: geometry.size.width, height: geometry.size.height)
      }.clearDetailItem()
    }

    private func masterView(geometry: GeometryProxy) -> some View {
      StackNavigationView {
        self.masterContent
      }
      .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
      .frame(height: geometry.size.height)
    }

    private func detailView(geometry: GeometryProxy) -> some View {
      StackNavigationView {
        self.rootDetailWaypointContent?.view
          .waypoint(with: self.rootDetailWaypointContent?.waypoint)
      }.layoutPriority(1)
    }
  }

#endif
