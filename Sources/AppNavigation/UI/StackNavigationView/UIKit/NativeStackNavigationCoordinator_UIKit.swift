#if canImport(UIKit)
  import Combine
  import SwiftDux
  import SwiftUI

  internal struct StackItem: Equatable {
    var path: String
    var viewController: UIViewController

    init(path: String, viewController: UIViewController) {
      self.path = path
      self.viewController = viewController
    }

    init<V>(path: String, view: V) where V: View {
      self.init(
        path: path,
        viewController: UIHostingController(rootView: view)
      )
    }

    static func == (lhs: StackItem, rhs: StackItem) -> Bool {
      lhs.path == rhs.path
    }
  }

  internal final class StackNavigationCoordinator: NSObject {
    weak var navigationController: UINavigationController? {
      willSet {
        navigationController?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
      }
      didSet {
        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.navigationBar.prefersLargeTitles = true
        updateNavigation(animate: animate)
      }
    }

    var waypoint: Waypoint
    var detailContent: RootDetailWaypointContent?
    var animate: Bool

    private var rootViewController: UIViewController?
    private var rootDetailViewController: UIViewController?
    private var rootDetailPath: String?

    private var options: StackNavigationOptions = StackNavigationOptions()
    private var detailOptions: StackNavigationOptions = StackNavigationOptions()

    private var dispatch: ActionDispatcher
    private var stackItems: [StackItem] = []
    private var detailStackItems: [StackItem] = []
    private var viewControllersByPath: [String: UIViewController] = [:]
    private var currentViewControllers: [UIViewController] = []
    private var showSplitViewDisplayModeButton: Bool = false {
      didSet { updateSplitNavigationDisplayModeButton() }
    }

    private var enableSwipeNavigation: Bool = true {
      didSet {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enableSwipeNavigation
      }
    }

    init<Content>(
      dispatch: ActionDispatcher,
      waypoint: Waypoint,
      detailContent: RootDetailWaypointContent?,
      animate: Bool,
      rootView: Content
    ) where Content: View {
      self.dispatch = dispatch
      self.waypoint = waypoint
      self.animate = animate

      super.init()

      setRootView(rootView: rootView)
      setRootDetailView(content: detailContent)
    }

    func setRootView<Content>(rootView: Content?) where Content: View {
      self.setRootViewInternal(
        rootView:
          rootView
          .onPreferenceChange(StackNavigationPreferenceKey.self) { [weak self] in
            self?.updatePreferences(preference: $0, isDetail: false)
          }
          .clearDetailItem(),
        isDetail: false
      )
    }

    func setRootDetailView(content: RootDetailWaypointContent?) {
      guard content != nil else {
        rootDetailViewController = nil
        return
      }
      self.setRootViewInternal(
        rootView: content?.view
          .onPreferenceChange(StackNavigationPreferenceKey.self) { [weak self] in
            self?.updatePreferences(preference: $0, isDetail: true)
          }
          .clearDetailItem(),
        isDetail: true
      )
      self.rootDetailPath = content?.waypoint.path
    }

    private func setRootViewInternal<V>(rootView: V, isDetail: Bool) where V: View {
      var controller = isDetail ? rootDetailViewController : rootViewController
      var needsUpdate = false
      if let controller = controller as? UIHostingController<V> {
        controller.rootView = rootView
      } else {
        controller = UIHostingController<V>(rootView: rootView)
        needsUpdate = true
      }
      if isDetail {
        rootDetailViewController = controller
      } else {
        rootViewController = controller
      }
      if needsUpdate {
        updateCurrentViewControllers(animate: animate)
      }
    }

    private func updatePreferences(preference: StackNavigationPreference, isDetail: Bool) {
      if isDetail {
        self.detailOptions = preference.options
      } else {
        self.options = preference.options
      }
      updateStackItems(preference.stack, isDetail: isDetail, animate: preference.animate)
    }

    private func updateStackItems(_ newStackItems: [StackItem], isDetail: Bool, animate: Bool) {
      let stackItems = isDetail ? self.detailStackItems : self.stackItems
      let newStackItemByPath = Set(newStackItems.map(\.path))
      stackItems.forEach {
        if !newStackItemByPath.contains($0.path) {
          viewControllersByPath.removeValue(forKey: $0.path)
        }
      }
      newStackItems.forEach {
        if viewControllersByPath[$0.path] == nil && $0.path.starts(with: waypoint.path) {
          viewControllersByPath[$0.path] = $0.viewController
        }
      }
      if isDetail {
        self.detailStackItems = newStackItems
      } else {
        self.stackItems = newStackItems
      }
      updateCurrentViewControllers(animate: animate)
    }

    private func updateOptions(_ options: StackNavigationOptions) {
      self.enableSwipeNavigation = options.swipeGesture
      self.navigationController?.hidesBarsOnTap = options.hideBarsOnTap
      self.navigationController?.hidesBarsOnSwipe = options.hideBarsOnSwipe
      self.navigationController?.hidesBarsWhenKeyboardAppears = options.hidesBarsWhenKeyboardAppears
      self.navigationController?.hidesBarsWhenVerticallyCompact = options.hidesBarsWhenVerticallyCompact
      self.navigationController?.navigationBar.tintColor = options.barTintColor
      self.showSplitViewDisplayModeButton = options.showSplitViewDisplayModeButton
    }

    func updateCurrentViewControllers(animate: Bool) {
      guard let rootViewController = rootViewController else { return }
      var viewControllers: [UIViewController] =
        [rootViewController]
        + stackItems.compactMap {
          self.viewControllersByPath[$0.path]
        }

      if let rootDetailViewController = rootDetailViewController {
        viewControllers.append(rootDetailViewController)
        viewControllers.append(contentsOf: detailStackItems.compactMap { self.viewControllersByPath[$0.path] })
      }
      self.currentViewControllers = viewControllers
      updateNavigation(animate: animate)
    }

    func updateNavigation(animate: Bool) {
      self.updateOptions(options)
      if rootDetailViewController != nil {
        self.updateOptions(detailOptions)
      }
      guard navigationController?.viewControllers != currentViewControllers else {
        return
      }
      if let nextViewController = currentViewControllers.last {
        prerenderViewController(viewController: nextViewController)
      }
      navigationController?.setViewControllers(
        currentViewControllers,
        animated: currentViewControllers.count > 1 && animate
      )
    }

    private func updateSplitNavigationDisplayModeButton() {
      guard let viewController = navigationController?.viewControllers.first else { return }
      guard let button = viewController.splitViewController?.displayModeButtonItem else { return }
      if showSplitViewDisplayModeButton {
        viewController.navigationItem.leftBarButtonItem = button
        viewController.navigationItem.leftItemsSupplementBackButton = true
      } else if viewController.navigationItem.leftBarButtonItem == button {
        viewController.navigationItem.leftBarButtonItem = nil
        viewController.navigationItem.leftItemsSupplementBackButton = false
      }
    }

    /// Pre-render a SwiftUI hosted view, so the navigation item is ready.
    ///
    /// SwiftUI is built on top of UIViews which use CALayer. CALayer cannot layout or render until they are in a graphics context.
    /// One way to handle this is to add the SwiftUI hosted view to a view controller that's already attached to a window. The render method
    /// of UIHostingView crashes if it's called
    /// - Parameter viewController: The view controller.
    private func prerenderViewController(viewController: UIViewController) {
      guard viewController.navigationController == nil else { return }
      guard viewController.splitViewController == nil else { return }
      if viewController.parent == nil {
        navigationController?.addChild(viewController)
        navigationController?.view.addSubview(viewController.view)
        viewController.view.layoutSubviews()
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
      } else {
        viewController.view.layoutSubviews()
      }
    }
  }

  extension StackNavigationCoordinator: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
      updateSplitNavigationDisplayModeButton()
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
      guard viewController != rootViewController else {
        if !viewControllersByPath.isEmpty {
          dispatch(waypoint.navigate(to: waypoint.path, animate: false))
          dispatch(waypoint.completeNavigation())
          viewControllersByPath = [:]
        }
        if !waypoint.isDetail && rootDetailViewController != nil {
          dispatch(waypoint.navigate(to: "/", isDetail: true, animate: false))
          dispatch(waypoint.completeNavigation(isDetail: true))
        }
        return
      }
      var path: String?
      if let vcIndex = viewControllersByPath.firstIndex(where: { key, vc in vc == viewController }) {
        path = viewControllersByPath.keys[vcIndex]
      } else if viewController == rootDetailViewController {
        path = rootDetailPath ?? "/"
      }
      if let path = path, let stackItem = (stackItems + detailStackItems).last {
        if stackItem.path != path {
          viewControllersByPath[stackItem.path] = nil
          dispatch(
            waypoint.navigate(
              to: path,
              isDetail: detailStackItems.isEmpty ? waypoint.isDetail : true,
              animate: false
            )
          )
          dispatch(waypoint.completeNavigation())
        }
      }
    }
  }

  extension StackNavigationCoordinator: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      return enableSwipeNavigation
    }
  }

#endif
