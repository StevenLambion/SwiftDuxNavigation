# SwiftDux Navigation (Experimental)

> Provides deep link routing to SwiftUI applications powered by [SwiftDux](https://github.com/StevenLambion/SwiftDux).

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]

This is an experimental library that implements a deep-link routing API for SwiftDux applications. It's currently in an early proof-of-concept stage. Its goal is focused on the routing of an application with minimal additions to the built-in SwiftUI views.

## Features
- Deep link style navigation.
- Save and restore navigation between sessions by persisting the SwiftDux state.
- Scene support to create separate routes between windows or UIScenes.

## Views
- `RootNavigationView` - Initiates the ground work.
    - Shares environment objects across view hierarchies.
- `StackNavigationView` - Stacks routes on top of each other.
  - Use gestures to navigate back or hide the navigation bar.
  - Works with SwiftUI's navigation bar API.
- `TabNavigationView` - Display a tab view of routable branches.
- `Redirect` - Conditionally redirects the route.
- `RouteContents` - Create custom route views.

## Modals
- `View.sheetRoute(_:content:)` - Displays a sheet as a route.
- `View.actionSheetRoute(_:content:)` - Displays an action sheet as a route.
- `View.alertRoute(_:content:)` - Displays an alert as a route.

## Things to do
- Error handling
- Graceful recovery of invalid routes.
- macOS support
- SplitView support
- Save routing state of inactive tabs.

[swift-image]: https://img.shields.io/badge/swift-5.2-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE

## Getting started

1. Add navigation to the application state with `NavigationStateRoot`
    ```swift
      struct AppState: NavigationStateRoot {
        var navigation: NavigationState = NavigationState()
      }
    ```

1. Add the navigation reducer to the store.
    ```swift
      Store(state: AppState(), reducer: AppReducer() + NavigationReducer())
    ```

1. Wrap your root view with `RootNavigationView`. Then attach any environment objects outside of the `RootNavigationView`. If the environment objects are not injected outside of this view, they may not propagate to all view hierarchies.
    ```swift
      RootNavigationView {
        RootView()
      }.provideStore(store)
    ```

1. Provide the SwiftDux store a second time using the `NavigationStateRoot` protocol. This allows SwiftDuxNavigation's views to access it.
    ```swift
    RootNavigationView {
      RootView()
    }
    .provideStore(store)
    .provideStore(store, as: NavigationStateRoot.self)
    ```
1. Optionally, specify the current scene when creating a new window or UIScene. By default, the routing uses a "main" scene to conduct navigation.
    ```swift
      UIHostingController(
        rootView: SecondaryView().scene(named: session.persistentIdentifier)
      )
    ```
    Clean up any unneeded scenes by dispatching `NavigationAction.clearScene(named:)`.
    ```swift
    // Inside the AppDelegate
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
      sceneSessions.forEach { session in
        store.dispatch(NavigationAction.clearScene(named: sceneSessions.persistentIdentifier))
      }
    }
    ```

## Route Precedence
The precedence of an active route is based on its position in the view hierarchy. In cases where two or more routes share the same parent route, the higher-level route will be chosen. In the following example, the alert route will take precedence over the stack route when the relative route is set to "display-alert".
```swift
List {
  ...
}
.stackRoute { id in
  RecipeEditorContainer(id: id)
}
.alertRoute("display-alert") { Alert(title: Text("Hello world!")) }
```

## Examples

### Live Example

[Checkout the SwiftDux Todo Example](https://github.com/StevenLambion/SwiftUI-Todo-Example/tree/swiftdux-navigation).

### RouteLink
Navigate to a new route relative to the containing view.

```swift
// Pass a single path parameter or component.
let id = 123
RouteLink(path: id) { Text("Label") }

// Go up a level
RouteLink(path: "..")  { Text("Label") }

// Absolute path
RouteLink(path: "/person/\(id)/company")  { Text("Label") }
```

### TabNavigationView
```swift
TabNavigationView(initialTab: "allMusic") {
  AllMusicContainer()
    .tabItem { Text("All Music") }
    .tag("allMusic")
  AlbumsContainer()
    .tabItem { Text("Albums") }
    .tag("albums")
  PlaylistsContainer()
    .tabItem { Text("Playlists") }
    .tag("playlists")
}
```

### StackNavigationView
Create a new `StackNavigationView` to display the app's navigation as a stack. The `View.stackRoute()` methods create the next item in the stack. Think of them as a UIViewController in a UINavigationController. The view inside the route is a branch, and a route may contain one or more of them. In the example, a new route is created with a single branch that displays the `ItemDetails(id:)` view.

When a user taps the `RouteLink`, it will navigate to the route with the `ItemDetails(id:)`. The id type can be anything that is convertible from a `String` such as an `Int`. The library automatically converts path parameters to match the type required by the route.

```swift
StackNavigationView {
  List {
    ForEach(items) { item in
      RouteLink(path: item.id) {
        Text(item.name)
      }
    }
  }
  .navigationBarTitle(Text("Items"), displayMode: .large)
  .hideNavigationBar(onSwipe: true)
  .stackRoute { id in
    ItemDetails(id: id)
  }
}
```
#### Static branching
To add multiple branches to a route, use the `View.branch(_:isDefault:)` method. This gives the branches a name to specify the active one. Think of it as the `View.tag(_:)` method for a `TabView`. In cases where a branch isn't specified, the application can redirect to a default one.

```swift
StackNavigationView {
  AppSectionList()
    .stackRoute {
      recipes().branch("company", isDefault: true)
      shoppingList().branch("contact")
      settings().branch("settings")
    }
}

// In a view: 
RouteLink(path: "/settings")
```

#### Dynamic branching
Dynamic routes pass their last path component to its branches as a path parameter. In some cases, this may lead to two or more consecutive dynamic routes that form a path made up entirely of path parameters. To resolve this, specify branch names on the dynamic routes.

```swift
StackNavigationView {
  List {
    ForEach(items) { item in
      RouteLink(path: "\(item.id)/companies") {
        PersonRow(item)
      }
    }
  }.stackRoute { id in
    CompanyDetails(id: id).branch("companies", isDefault: true)
    ContactDetails(id: id).branch("contact")
  }
}

// In a view somewhere else: 
RouteLink(path: "/people/\(person.id)/companies/\(company.id)")
```