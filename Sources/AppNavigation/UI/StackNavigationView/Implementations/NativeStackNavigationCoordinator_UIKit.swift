#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackItem: Equatable {
    var path: String
    var viewController: UIViewController

    init(path: String, viewController: UIViewController) {
      self.path = path
      self.viewController = viewController
    }

    init<V>(path: String, fromBranch: Bool = false, view: V) where V: View {
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
        updateNavigation()
      }
    }

    var waypoint: Waypoint
    var detailContent: RootDetailWaypointContent?
    var animate: Bool

    private var rootViewController: UIViewController?
    private var rootDetailViewController: UIViewController?

    private var options: StackNavigationOptions = StackNavigationOptions()
    private var detailOptions: StackNavigationOptions = StackNavigationOptions()

    private var dispatch: ActionDispatcher
    private var stackItems: [StackItem] = []
    private var detailStackItems: [StackItem] = []
    private var viewControllersByPath: [String: UIViewController] = [:]
    private var replaceRoot: Bool = false {
      didSet {
        if replaceRoot != oldValue {
          updateNavigation()
        }
      }
    }
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
      detailContent: AnyView?,
      animate: Bool,
      rootView: Content
    ) where Content: View {
      self.dispatch = dispatch
      self.waypoint = waypoint
      self.animate = animate
      super.init()
      setRootView(rootView: rootView, isDetail: false)
      setRootView(rootView: detailContent, isDetail: true)
    }

    func setRootView<Content>(rootView: Content?, isDetail: Bool) where Content: View {
      guard rootView != nil else {
        if isDetail {
          rootDetailViewController = nil
        }
        return
      }
      self.setRootViewInternal(
        rootView: (rootView
          .onPreferenceChange(StackNavigationPreferenceKey.self) { [weak self] in
            if isDetail {
              self?.detailOptions = $0
            } else {
              self?.options = $0
            }
          }
          .onPreferenceChange(StackItemPreferenceKey.self) { [weak self] in
            self?.updateStackItems($0, isDetail: isDetail)
          }
          // Don't let parent navigation views use the routes.
          .preference(key: StackItemPreferenceKey.self, value: [])
          .clearDetailItem()),
        isDetail: isDetail
      )
    }

    private func setRootViewInternal<V>(rootView: V, isDetail: Bool) where V: View {
      var controller = isDetail ? rootDetailViewController : rootViewController
      if let controller = controller as? UIHostingController<V> {
        controller.rootView = rootView
      } else {
        controller = UIHostingController<V>(rootView: rootView)
      }
      if isDetail {
        rootDetailViewController = controller
      } else {
        rootViewController = controller
      }
    }

    private func updateStackItems(_ newStackItems: [StackItem], isDetail: Bool) {
      let stackItems = isDetail ? self.detailStackItems : self.stackItems
      guard stackItems != newStackItems else { return }
      let newStackItemByPath = Set(newStackItems.map(\.path))
      stackItems.forEach {
        if !newStackItemByPath.contains($0.path) {
          viewControllersByPath.removeValue(forKey: $0.path)
        }
      }
      newStackItems.forEach {
        if viewControllersByPath[$0.path] == nil {
          viewControllersByPath[$0.path] = $0.viewController
        }
      }
      if isDetail {
        self.detailStackItems = newStackItems
      } else {
        self.stackItems = newStackItems
      }
      updateNavigation()
    }

    private func updateOptions(_ options: StackNavigationOptions) {
      self.enableSwipeNavigation = options.swipeGesture
      self.navigationController?.hidesBarsOnTap = options.hideBarsOnTap
      self.navigationController?.hidesBarsOnSwipe = options.hideBarsOnSwipe
      self.navigationController?.hidesBarsWhenKeyboardAppears = options.hidesBarsWhenKeyboardAppears
      self.navigationController?.hidesBarsWhenVerticallyCompact = options.hidesBarsWhenVerticallyCompact
      self.navigationController?.navigationBar.tintColor = options.barTintColor
      self.replaceRoot = options.replaceRoot
      self.showSplitViewDisplayModeButton = options.showSplitViewDisplayModeButton
    }

    func updateNavigation() {
      guard let rootViewController = rootViewController else { return }
      var viewControllers: [UIViewController] = stackItems.compactMap { self.viewControllersByPath[$0.path] }

      self.updateOptions(options)
      if let rootDetailViewController = rootDetailViewController {
        viewControllers.append(rootDetailViewController)
        viewControllers.append(contentsOf: detailStackItems.compactMap { self.viewControllersByPath[$0.path] })
        self.updateOptions(detailOptions)
      }

      if viewControllers.count == 0 || !replaceRoot {
        viewControllers.insert(rootViewController, at: 0)
      }

      if navigationController?.viewControllers == viewControllers {
        return
      }

      let animate = viewControllers.count > 1 && self.animate
      if let nextViewController = viewControllers.last {
        prerenderViewController(viewController: nextViewController)
      }
      navigationController?.setViewControllers(viewControllers, animated: animate)
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
      prerenderViewController(viewController: viewController)
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
      guard let vcIndex = viewControllersByPath.firstIndex(where: { key, vc in vc == viewController })
      else { return }
      let path = viewControllersByPath.keys[vcIndex]
      if let stackItem = (stackItems + detailStackItems).last {
        if stackItem.path != path {
          dispatch(waypoint.navigate(to: path, isDetail: !detailStackItems.isEmpty, animate: false))
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
