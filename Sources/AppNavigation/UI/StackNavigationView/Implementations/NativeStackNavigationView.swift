#if !canImport(UIKit)

  import SwiftDux
  import SwiftUI

  internal struct StackRoute: Equatable {
    var path: String
    var fromBranch: Bool = false
    var view: AnyView

    init(path: String, fromBranch: Bool = false, view: AnyView) {
      self.path = path
      self.fromBranch = fromBranch
      self.view = view
    }

    init<V>(path: String, fromBranch: Bool = false, view: V) where V: View {
      self.init(path: path, fromBranch: fromBranch, view: AnyView(view))
    }

    static func == (lhs: StackRoute, rhs: StackRoute) -> Bool {
      lhs.path == rhs.path
    }
  }

  internal struct NativeStackNavigationView<RootView>: View where RootView: View {
    @Environment(\.routeInfo) private var routeInfo

    var rootPath: String
    var animate: Bool
    var rootView: RootView

    @State private var push: Bool = true
    @State private var routeCount: Int = 0
    @State private var activeRoute: StackRoute? = nil

    var transition: AnyTransition {
      push
        ? AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        : AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    var body: some View {
      ZStack {
        Group {
          if activeRoute == nil {
            rootView.id(self.routeInfo.path + ":root")
              .onPreferenceChange(StackRoutePreferenceKey.self) { self.updateActiveRoute($0) }
              .zIndex(1)
          } else {
            activeRoute.map {
              $0.view.id($0.path)
                .background(Color.white)
                .zIndex(2)
            }
          }
        }.transition(transition)
      }
    }

    func updateActiveRoute(_ routes: [StackRoute]) {
      let updater = {
        self.push = self.routeCount < routes.count
        self.routeCount = routes.count
        self.activeRoute = routes.last
      }
      if animate {
        withAnimation(.easeIn(duration: 1), updater)
      } else {
        updater()
      }
    }
  }

#endif
