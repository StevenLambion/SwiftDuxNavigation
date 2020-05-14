#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackRoute: Equatable {
    var path: String
    var fromBranch: Bool = false
    var viewController: () -> UIViewController

    init(path: String, fromBranch: Bool = false, viewController: @escaping () -> UIViewController) {
      self.path = path
      self.fromBranch = fromBranch
      self.viewController = viewController
    }

    init<V>(path: String, fromBranch: Bool = false, view: V) where V: View {
      self.init(path: path, fromBranch: fromBranch, viewController: { UIHostingController(rootView: view) })
    }

    static func == (lhs: StackRoute, rhs: StackRoute) -> Bool {
      lhs.path == rhs.path
    }
  }

  internal final class StackNavigationCoordinator: NSObject {
    var rootPath: String = "/"
    var animate: Bool = true

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
        updateNavigation()
      }
    }

    private var dispatch: ActionDispatcher
    private var routes: [StackRoute] = []
    private var viewControllersByPath: [String: UIViewController] = [:]

    init(dispatch: ActionDispatcher) {
      self.dispatch = dispatch
      super.init()
    }

    func setRootView<V>(rootView: V) where V: View {
      self.setRootViewInternal(
        rootView: rootView.onPreferenceChange(StackRoutePreferenceKey.self) { [weak self] in
          self?.updateRoutes($0)
        }
      )
    }

    private func setRootViewInternal<V>(rootView: V) where V: View {
      guard let rootViewController = rootViewController as? UIHostingController<V> else {
        return self.rootViewController = UIHostingController<V>(rootView: rootView)
      }
      rootViewController.rootView = rootView
    }

    private func updateRoutes(_ newRoutes: [StackRoute]) {
      guard self.routes != newRoutes else { return }
      let newRoutesByPath = Set(newRoutes.map(\.path))
      routes.forEach {
        if !newRoutesByPath.contains($0.path) {
          viewControllersByPath.removeValue(forKey: $0.path)
        }
      }
      newRoutes.forEach {
        if viewControllersByPath[$0.path] == nil {
          viewControllersByPath[$0.path] = $0.viewController()
        }
      }
      self.routes = newRoutes
      updateNavigation()
    }

    private func updateNavigation() {
      guard let rootViewController = rootViewController else { return }
      let viewControllers: [UIViewController] =
        [rootViewController] + routes.compactMap { self.viewControllersByPath[$0.path] }
      navigationController?.setViewControllers(viewControllers, animated: animate)
    }
  }

  extension StackNavigationCoordinator: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
      guard viewController != rootViewController else {
        if !viewControllersByPath.isEmpty {
          dispatch(NavigationAction.navigate(to: rootPath, animate: false))
          dispatch(NavigationAction.completeRouting(scene: "main"))
        }
        return
      }
      guard let vcIndex = viewControllersByPath.firstIndex(where: { key, vc in vc == viewController })
      else { return }
      let path = viewControllersByPath.keys[vcIndex]
      if let route = routes.last {
        if route.path != path {
          dispatch(NavigationAction.pop(to: path, in: "main", preserveBranch: route.fromBranch, animate: false))
          dispatch(NavigationAction.completeRouting(scene: "main"))
        }
      }
    }
  }

  extension StackNavigationCoordinator: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
    }
  }

#endif
