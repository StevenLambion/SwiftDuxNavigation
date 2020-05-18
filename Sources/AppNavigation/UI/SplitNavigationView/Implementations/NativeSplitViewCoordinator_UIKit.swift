#if canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal final class NativeSplitNavigationViewCoordinator<MasterContent>: NSObject, UISplitViewControllerDelegate where MasterContent: View {
    weak var splitViewController: UISplitViewController? {
      didSet { splitViewController?.delegate = self }
    }

    var splitNavigationOptions: Set<SplitNavigationOption> = SplitNavigationOption.defaultOptions {
      didSet { self.updateOptions(splitNavigationOptions) }
    }

    var detailRoutes: [String: AnyView] = [:]
    var activeDetailRoute: String? = nil
    var currentRoute: CurrentRoute = CurrentRoute()
    var animate: Bool = true
    var isCollapsed: Bool = false {
      didSet { splitViewContext.isCollapsed = isCollapsed }
    }

    private var splitViewContext = SplitViewContext()
    private var masterViewController: SplitViewUIHostingController<AnyView>?
    private var detailViewController: SplitViewUIHostingController<AnyView>?
    private var showDisplayModeButton: Bool = true

    private var detailContent: AnyView? {
      guard let activeDetailRoute = activeDetailRoute else { return nil }
      return detailRoutes[activeDetailRoute]
    }

    func setMasterContent(_ masterContent: MasterContent) {
      updateMasterNavigationView(masterContent: masterContent)
      var viewControllers: [UIViewController] = [masterViewController!]

      if !isCollapsed {
        updateDetailNavigationView()
        viewControllers.append(detailViewController!)
      } else {
        detailViewController = nil
      }
      self.splitViewController?.viewControllers = viewControllers
    }

    private func updateMasterNavigationView(masterContent: MasterContent) {
      let detailContent = self.detailContent
      let masterView = SplitViewContextProvider { context in
        if context.masterIsReady {
          StackNavigationView {
            if context.isCollapsed && detailContent != nil && self.activeDetailRoute != "/" {
              masterContent.stackRoute {
                detailContent
              }.environment(\.currentRoute, CurrentRoute(path: "/", isDetail: true))
            } else {
              masterContent
            }
          }
        }
      }.environmentObject(splitViewContext)

      if masterViewController == nil {
        masterViewController = SplitViewUIHostingController(
          isReady: { [weak self] in self?.splitViewContext.masterIsReady = $0 },
          rootView: AnyView(masterView)
        )
      } else {
        masterViewController?.rootView = AnyView(masterView)
      }
    }

    private func updateDetailNavigationView() {
      let detailContent = self.detailContent
      let detailView = SplitViewContextProvider { context in
        if context.detailIsReady {
          StackNavigationView {
            detailContent?.stackNavigationReplaceRoot(true)
          }
          .environment((\.currentRoute), CurrentRoute(sceneName: self.currentRoute.sceneName, isDetail: true))
        }
      }
      .environment(\.splitNavigationDisplayModeButton, showDisplayModeButton ? splitViewController?.displayModeButtonItem : nil)
      .environmentObject(splitViewContext)

      if detailViewController == nil {
        detailViewController = SplitViewUIHostingController(
          isReady: { [weak self] in self?.splitViewContext.detailIsReady = $0 },
          rootView: AnyView(detailView)
        )
      } else {
        detailViewController?.rootView = AnyView(detailView)
      }
    }

    private func updateOptions(_ options: Set<SplitNavigationOption>) {
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

    /// Makes sure SwiftUI doesn't render the contents until the controller is in the view heirarchy.
    private final class SplitViewUIHostingController<RootView>: UIHostingController<RootView> where RootView: View {
      var isReady: (Bool) -> Void = { _ in }

      init(isReady: @escaping (Bool) -> Void, rootView: RootView) {
        self.isReady = isReady
        super.init(rootView: rootView)
      }

      @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }

      override func didMove(toParent parent: UIViewController?) {
        isReady(parent != nil)
      }
    }

    private final class SplitViewContext: ObservableObject {
      @Published var masterIsReady: Bool = false
      @Published var detailIsReady: Bool = false
      @Published var isCollapsed: Bool = false
    }

    private struct SplitViewContextProvider<DetailContent>: View where DetailContent: View {
      @EnvironmentObject private var context: SplitViewContext
      private var content: (SplitViewContext) -> DetailContent

      init(@ViewBuilder content: @escaping (SplitViewContext) -> DetailContent) {
        self.content = content
      }

      var body: some View {
        content(context)
      }
    }
  }

#endif
