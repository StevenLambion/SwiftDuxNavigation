#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  class Test<RootView>: UIHostingController<RootView> where RootView: View {
    override var navigationItem: UINavigationItem {
      return super.navigationItem
    }

    override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
    }
  }

  internal struct StackRoute: Equatable {
    var path: String
    var fromBranch: Bool = false
    var viewController: UIViewController

    init(path: String, fromBranch: Bool = false, viewController: UIViewController) {
      self.path = path
      self.fromBranch = fromBranch
      self.viewController = viewController
    }

    init<V>(path: String, fromBranch: Bool = false, view: V) where V: View {
      self.init(path: path, fromBranch: fromBranch, viewController: Test(rootView: view))
    }

    static func == (lhs: StackRoute, rhs: StackRoute) -> Bool {
      lhs.path == rhs.path
    }
  }

  internal final class StackNavigationCoordinator: NSObject {
    var currentRoute: CurrentRoute
    var animate: Bool
    var splitNavigationDisplayModeButton: UIBarButtonItem?

    var rootViewController: UIViewController?
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

    private var dispatch: ActionDispatcher
    private var routes: StackRouteStorage = StackRouteStorage()
    private var viewControllersByPath: [String: UIViewController] = [:]
    private var replaceRoot: Bool = false {
      didSet {
        if replaceRoot != oldValue {
          updateNavigation()
        }
      }
    }

    private var enableSwipeNavigation: Bool = true {
      didSet {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enableSwipeNavigation
      }
    }

    init<Content>(
      dispatch: ActionDispatcher,
      currentRoute: CurrentRoute,
      animate: Bool,
      splitNavigationDisplayModeButton: UIBarButtonItem?,
      rootView: Content
    ) where Content: View {
      self.dispatch = dispatch
      self.currentRoute = currentRoute
      self.animate = animate
      self.splitNavigationDisplayModeButton = splitNavigationDisplayModeButton
      super.init()
      setRootView(rootView: rootView)
    }

    func setRootView<Content>(rootView: Content) where Content: View {
      self.setRootViewInternal(
        rootView:
          rootView
          .onPreferenceChange(StackRoutePreferenceKey.self) { [weak self] in
            self?.updateRoutes($0)
          }.onPreferenceChange(StackNavigationPreferenceKey.self) { [weak self] in
            self?.updateOptions($0)
          }
          // Don't let parent navigation views use the routes.
          .stackRoutePreference(StackRouteStorage())
          .environment(\.splitNavigationDisplayModeButton, nil)
      )
    }

    private func setRootViewInternal<V>(rootView: V) where V: View {
      guard let rootViewController = rootViewController as? UIHostingController<V> else {
        return self.rootViewController = UIHostingController<V>(rootView: rootView)
      }
      rootViewController.rootView = rootView
    }

    private func updateRoutes(_ newRoutes: StackRouteStorage) {
      guard self.routes != newRoutes else { return }
      let newRoutesByPath = Set(newRoutes.all.map(\.path))
      routes.all.forEach {
        if !newRoutesByPath.contains($0.path) {
          viewControllersByPath.removeValue(forKey: $0.path)
        }
      }
      newRoutes.all.forEach {
        if viewControllersByPath[$0.path] == nil {
          viewControllersByPath[$0.path] = $0.viewController
        }
      }
      self.routes = newRoutes
      updateNavigation()
    }

    private func updateOptions(_ options: Set<StackNavigationOption>) {
      options.forEach { option in
        switch option {
        case .swipeGesture(let enabled):
          self.enableSwipeNavigation = enabled
        case .hideBarsOnTap(let enabled):
          self.navigationController?.hidesBarsOnTap = enabled
        case .hideBarsOnSwipe(let enabled):
          self.navigationController?.hidesBarsOnSwipe = enabled
        case .hidesBarsWhenKeyboardAppears(let enabled):
          self.navigationController?.hidesBarsWhenKeyboardAppears = enabled
        case .hidesBarsWhenVerticallyCompact(let enabled):
          self.navigationController?.hidesBarsWhenVerticallyCompact = enabled
        case .barTintColor(let color):
          self.navigationController?.navigationBar.tintColor = color
        case .replaceRoot(let enabled):
          self.replaceRoot = enabled
        }
      }
    }

    private func updateNavigation() {
      guard let rootViewController = rootViewController else { return }
      var viewControllers: [UIViewController] = routes.all.compactMap { self.viewControllersByPath[$0.path] }

      if viewControllers.count == 0 || !replaceRoot {
        viewControllers.insert(rootViewController, at: 0)
      }

      let animate = viewControllers.count > 1 && self.animate

      // This is a hack to get UIHostingController to pre-render before getting pushed on the stack. without it
      // the navigationItem won't be set until after the animation. This might explain NavigationLink's destination
      // behavior.
      if shouldPerformPush(with: viewControllers) {
        let nextViewController = viewControllers.last!
        prerenderViewController(viewController: nextViewController)
        navigationController?.pushViewController(nextViewController, animated: animate)
      } else {
        navigationController?.setViewControllers(viewControllers, animated: animate)
      }
      if let splitNavigationDisplayModeButton = splitNavigationDisplayModeButton {
        rootViewController.navigationItem.leftBarButtonItem = splitNavigationDisplayModeButton
        rootViewController.navigationItem.leftItemsSupplementBackButton = true
      } else {
        rootViewController.navigationItem.leftBarButtonItem = nil
        rootViewController.navigationItem.leftItemsSupplementBackButton = false
      }
    }

    private func shouldPerformPush(with viewControllers: [UIViewController]) -> Bool {
      guard let currentCount = navigationController?.viewControllers.count else { return false }
      guard currentCount > 0 && viewControllers.count - 1 == currentCount else { return false }
      for i in 0..<currentCount {
        if viewControllers[i] != navigationController?.viewControllers[i] {
          return false
        }
      }
      return true
    }

    /// Pre-render a SwiftUI hosted view, so the navigation item is ready.
    ///
    /// SwiftUI is built on top of UIViews which use CALayer. CALayer cannot layout or render until they are in a graphics context.
    /// One way to handle this is to add the SwiftUI hosted view to a view controller that's already attached to a window.
    /// - Parameter viewController: The view controller.
    private func prerenderViewController(viewController: UIViewController) {
      navigationController?.addChild(viewController)
      navigationController?.view.addSubview(viewController.view)
      viewController.view.layer.layoutSublayers()
      viewController.view.removeFromSuperview()
      viewController.removeFromParent()
    }
  }

  extension StackNavigationCoordinator: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
      viewController.viewDidLayoutSubviews()
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
      guard viewController != rootViewController else {
        if !viewControllersByPath.isEmpty {
          dispatch(currentRoute.navigate(to: currentRoute.path, animate: false))
          dispatch(currentRoute.completeNavigation())
        }
        if !currentRoute.isDetail && !routes.detail.isEmpty {
          dispatch(currentRoute.navigate(to: "/", isDetail: true, animate: false))
          dispatch(currentRoute.completeNavigation(isDetail: true))
        }
        viewControllersByPath = [:]
        return
      }
      guard let vcIndex = viewControllersByPath.firstIndex(where: { key, vc in vc == viewController })
      else { return }
      let path = viewControllersByPath.keys[vcIndex]
      if let route = routes.all.last {
        if route.path != path {
          dispatch(currentRoute.pop(to: path, isDetail: !routes.detail.isEmpty, preserveBranch: route.fromBranch, animate: false))
          dispatch(currentRoute.completeNavigation())
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
