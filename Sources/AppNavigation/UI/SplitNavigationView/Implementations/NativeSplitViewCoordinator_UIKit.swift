#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal final class NativeSplitNavigationViewCoordinator<MasterContent>: NSObject, UISplitViewControllerDelegate where MasterContent: View {
    weak var splitViewController: UISplitViewController? {
      didSet { splitViewController?.delegate = self }
    }

    var store: AnyStore
    var detailRoutes: [String: () -> AnyView]
    var activeDetailRoute: String?
    var waypoint: Waypoint
    var isCollapsed: Bool

    private var masterViewController: UIViewController?
    private var detailViewController: UIViewController?
    private var showDisplayModeButton: Bool = true

    private var detailContent: (() -> AnyView)? {
      guard let activeDetailRoute = activeDetailRoute else { return nil }
      return detailRoutes[activeDetailRoute]
    }

    init(
      store: AnyStore,
      detailRoutes: [String: () -> AnyView],
      activeDetailRoute: String?,
      waypoint: Waypoint,
      isCollapsed: Bool,
      splitNavigationOptions: Set<SplitNavigationOption>,
      masterContent: MasterContent
    ) {
      self.store = store
      self.detailRoutes = detailRoutes
      self.activeDetailRoute = activeDetailRoute
      self.waypoint = waypoint
      self.isCollapsed = isCollapsed
      super.init()
      self.updateOptions(splitNavigationOptions)
      self.setMasterContent(masterContent)
    }

    func setMasterContent(_ masterContent: MasterContent) {
      updateMasterContent(masterContent: masterContent)
      updateDetailContent()
      if self.splitViewController?.viewControllers.count == 0 {
        self.splitViewController?.viewControllers = [masterViewController!, detailViewController!]
      }
    }

    func updateOptions(_ options: Set<SplitNavigationOption>) {
      options.forEach { option in
        switch option {
        case .showDisplayModeButton(let enabled):
          self.showDisplayModeButton = enabled
        case .preferredDisplayMode(let displayMode):
          self.splitViewController?.preferredDisplayMode = displayMode
        case .preferredPrimaryColumnWidthFraction(let value):
          self.splitViewController?.preferredPrimaryColumnWidthFraction = value
        case .presentsWithGesture(let enabled):
          self.splitViewController?.presentsWithGesture = enabled
        case .primaryEdge(let primaryEdge):
          self.splitViewController?.primaryEdge = primaryEdge
        case .primaryBackgroundStyle(let backgroundStyle):
          self.splitViewController?.primaryBackgroundStyle = backgroundStyle
        }
      }
    }

    private func updateMasterContent(masterContent: MasterContent) {
      let id = waypoint.path + "@split-navigation-master"
      let detailContent = self.detailContent
      let masterView = StackNavigationView {
        if isCollapsed && detailContent != nil && activeDetailRoute != "/" {
          masterContent.stackRoute {
            detailContent.map { $0() }
          }
          .resetRoute(with: "/", isDetail: true)
        } else {
          masterContent
        }
      }
      .id(id)
      .provideStore(self.store)
      
      updateMasterViewController(content: masterView)
    }

    private func updateMasterViewController<Content>(content: Content) where Content: View {
      if let masterViewController = masterViewController as? UIHostingController<Content> {
        masterViewController.rootView = content
      } else {
        masterViewController = UIHostingController(
          rootView: content
        )
      }
    }

    private func updateDetailContent() {
      let id = waypoint.path + "@split-navigation-detail"
      let detailContent = !isCollapsed ? self.detailContent : nil
      let detailView = StackNavigationView {
        detailContent.map { $0() }.stackNavigationReplaceRoot(true)
      }
      .id(id)
      .environment((\.waypoint), Waypoint(sceneName: self.waypoint.sceneName, isDetail: true))
      .environment(\.splitNavigationDisplayModeButton, showDisplayModeButton ? splitViewController?.displayModeButtonItem : nil)
      .provideStore(self.store)

      updateDetailViewController(content: detailView)
    }

    private func updateDetailViewController<Content>(content: Content) where Content: View {
      if let detailViewController = detailViewController as? UIHostingController<Content> {
        detailViewController.rootView = content
      } else {
        detailViewController = UIHostingController(
          rootView: content
        )
      }
    }
  }

#endif
