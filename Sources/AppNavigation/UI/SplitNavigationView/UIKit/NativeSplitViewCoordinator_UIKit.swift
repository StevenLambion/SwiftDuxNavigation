#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal final class NativeSplitNavigationViewCoordinator<MasterContent>: NSObject, UISplitViewControllerDelegate where MasterContent: View {
    weak var splitViewController: UISplitViewController? {
      didSet {
        splitViewController?.delegate = self
      }
    }

    var rootDetailWaypointContent: RootDetailWaypointContent?
    var waypoint: Waypoint
    var isCollapsed: Bool

    private var masterViewController: UIViewController?
    private var detailViewController: UIViewController?

    private var masterPreference: SplitNavigationPreference = SplitNavigationPreference()
    private var detailPreference: SplitNavigationPreference = SplitNavigationPreference()

    init(
      rootDetailWaypointContent: RootDetailWaypointContent?,
      waypoint: Waypoint,
      isCollapsed: Bool,
      masterContent: MasterContent
    ) {
      self.rootDetailWaypointContent = rootDetailWaypointContent
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
        masterViewController?.view.layoutIfNeeded()
        detailViewController?.view.layoutIfNeeded()
      }
    }

    private func updateMasterContent(masterContent: MasterContent) {
      let includeDetail = isCollapsed && rootDetailWaypointContent != nil && rootDetailWaypointContent?.waypoint.path != "/"
      let nextDetailWaypointContent =
        includeDetail
        ? rootDetailWaypointContent
        : nil
      let masterContent = StackNavigationView {
        masterContent.onPreferenceChange(SplitNavigationPreferenceKey.self) { [weak self] in
          self?.updatePreference(preference: $0, isDetail: false)
        }
      }
      .id(waypoint.path + "@split-navigation-master")
      .environment(\.rootDetailWaypointContent, nextDetailWaypointContent)
      updateMasterViewController(content: masterContent)
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
      let detailContent = !isCollapsed ? self.rootDetailWaypointContent : nil
      let detailView = StackNavigationView {
        detailContent?.view.onPreferenceChange(SplitNavigationPreferenceKey.self) { [weak self] in
          self?.updatePreference(preference: $0, isDetail: true)
        }
      }
      .waypoint(with: detailContent?.waypoint)
      .id(waypoint.path + "@split-navigation-detail")
      .clearDetailItem()

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

    func updatePreference(preference: SplitNavigationPreference, isDetail: Bool) {
      if isDetail {
        detailPreference = preference
      } else {
        masterPreference = preference
      }
      updateOptions()
    }

    func updateOptions() {
      var options = masterPreference.options
      detailPreference.optionTransformers.forEach { updater in
        updater(&options)
      }
      self.splitViewController?.preferredDisplayMode = options.preferredDisplayMode
      self.splitViewController?.preferredPrimaryColumnWidthFraction = options.preferredPrimaryColumnWidthFraction
      self.splitViewController?.presentsWithGesture = options.presentsWithGesture
      self.splitViewController?.primaryEdge = options.primaryEdge
      self.splitViewController?.primaryBackgroundStyle = options.primaryBackgroundStyle
    }
  }

#endif
