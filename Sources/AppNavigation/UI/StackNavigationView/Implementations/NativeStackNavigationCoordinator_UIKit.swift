#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

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
      self.init(path: path, fromBranch: fromBranch, viewController: UIHostingController(rootView: view))
    }

    static func == (lhs: StackRoute, rhs: StackRoute) -> Bool {
      lhs.path == rhs.path
    }
  }

  internal final class StackNavigationCoordinator: NSObject {
    var currentRoute: CurrentRoute = CurrentRoute()
    var animate: Bool = true
    var splitNavigationDisplayModeButton: UIBarButtonItem? = nil

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

    init(dispatch: ActionDispatcher) {
      self.dispatch = dispatch
      super.init()
    }

    func setRootView<V>(rootView: V) where V: View {
      self.setRootViewInternal(
        rootView:
          rootView
          .onPreferenceChange(StackRoutePreferenceKey.self) { [weak self] in
            self?.updateRoutes($0)
          }.onPreferenceChange(StackNavigationPreferenceKey.self) { [weak self] in
            self?.updateOptions($0)
          }
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
        let previousViewControllers = navigationController?.viewControllers
        navigationController?.setViewControllers(viewControllers, animated: false)
        navigationController?.setViewControllers(previousViewControllers!, animated: false)
        navigationController?.pushViewController(viewControllers.last!, animated: animate)
      } else if shouldPerformPop(with: viewControllers) || shouldRefresh(with: viewControllers) {
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

    private func shouldPerformPop(with viewControllers: [UIViewController]) -> Bool {
      guard let currentCount = navigationController?.viewControllers.count else { return false }
      guard currentCount > 0 && viewControllers.count <= currentCount else { return false }
      for i in 0..<currentCount {
        if viewControllers[i] != navigationController?.viewControllers[i] {
          return true
        }
      }
      return false
    }

    private func shouldRefresh(with viewControllers: [UIViewController]) -> Bool {
      navigationController?.viewControllers.first != rootViewController || navigationController?.viewControllers.count ?? 0 < viewControllers.count
    }
  }

  extension StackNavigationCoordinator: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
      guard viewController != rootViewController else {
        if !viewControllersByPath.isEmpty {
          dispatch(currentRoute.navigate(to: currentRoute.path, animate: false))
          dispatch(currentRoute.completeNavigation())
        }
        if !routes.detail.isEmpty {
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
