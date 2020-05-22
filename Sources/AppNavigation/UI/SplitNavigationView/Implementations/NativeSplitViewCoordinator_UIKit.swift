#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal final class NativeSplitNavigationViewCoordinator<MasterContent>: NSObject, UISplitViewControllerDelegate where MasterContent: View {
    weak var splitViewController: UISplitViewController? {
      didSet { splitViewController?.delegate = self }
    }

    //var store: AnyStore
    var detailRoutes: [String: () -> AnyView]
    var activeDetailRoute: String?
    var waypoint: Waypoint
    var isCollapsed: Bool

    private var masterViewController: UIViewController?
    private var detailViewController: UIViewController?

    private var detailContent: (() -> AnyView)? {
      guard let activeDetailRoute = activeDetailRoute else { return nil }
      return detailRoutes[activeDetailRoute]
    }

    init(
      //store: AnyStore,
      detailRoutes: [String: () -> AnyView],
      activeDetailRoute: String?,
      waypoint: Waypoint,
      isCollapsed: Bool,
      masterContent: MasterContent
    ) {
      //self.store = store
      self.detailRoutes = detailRoutes
      self.activeDetailRoute = activeDetailRoute
      self.waypoint = waypoint
      self.isCollapsed = isCollapsed
      super.init()
      self.setMasterContent(masterContent)
    }

    func setMasterContent(_ masterContent: MasterContent) {
      updateMasterContent(masterContent: masterContent)
      updateDetailContent()
      if self.splitViewController?.viewControllers.count == 0 {
        self.splitViewController?.viewControllers = [masterViewController!, detailViewController!]
      }
    }

    func updateOptions(options: SplitNavigationOptions) {
      self.splitViewController?.preferredDisplayMode = options.preferredDisplayMode
      self.splitViewController?.preferredPrimaryColumnWidthFraction = options.preferredPrimaryColumnWidthFraction
      self.splitViewController?.presentsWithGesture = options.presentsWithGesture
      self.splitViewController?.primaryEdge = options.primaryEdge
      self.splitViewController?.primaryBackgroundStyle = options.primaryBackgroundStyle
    }

    private func updateMasterContent(masterContent: MasterContent) {
      let masterContent = masterContent.onPreferenceChange(SplitNavigationPreferenceKey.self) { [weak self] in
        self?.updateOptions(options: $0)
      }
      let detailContent = self.detailContent
      let masterView = StackNavigationView {
        if isCollapsed && detailContent != nil && activeDetailRoute != "/" {
          masterContent.stackRoute {
            detailContent?()
          }
          .resetRoute(with: "/", isDetail: true)
        } else {
          masterContent
        }
      }
      .id(waypoint.path + "@split-navigation-master")

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
      let detailContent = !isCollapsed ? self.detailContent : nil
      let detailView = StackNavigationView {
        detailContent?()
      }
      .id(waypoint.path + "@split-navigation-detail")

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
