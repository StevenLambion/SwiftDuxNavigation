# SwiftDux Navigation (Experimental)

> Provides deep link routing in SwiftUI applications powered by [SwiftDux](https://github.com/StevenLambion/SwiftDux).

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]

SwiftDux Navigation implements deep-link routing for SwiftUI applications. It's currently in an early development stage. The library's goal is to take responsibility of the underlying navigational work of an application, so a developer can put more focus on higher-level needs.

## Features
- Route style navigation.
- Navigate by custom URL app scheme.
- Save and restore the navigation via `PersistStateMiddleware`.
- Multi-UIScene support.
- Master-detail routing.

## Navigation Views
- `SplitNavigationView`
  - Uses UISplitNavigationController on iOS.
    - Automatically handles the collapse and expand layouts.
    - Show or hide the display mode button.
- `StackNavigationView`
  - Uses UINavigationController on iOS.
    - Use gestures to navigate back or hide the navigation bar.
    - Works with SwiftUI's navigation bar API.
- `TabNavigationView`
  - Identical API to TabView.
  - Automatically saves and restores tab routes.
- `Redirect`
  - Conditionally redirects the route.

## Modals
- `View.sheetRoute(_:content:)` - Displays a sheet as a route.
- `View.actionSheetRoute(_:content:)` - Displays an action sheet as a route.
- `View.alertRoute(_:content:)` - Displays an alert as a route.

## Environment Values
- `currentRoute` - Get information about the current route relative to the view.

[swift-image]: https://img.shields.io/badge/swift-5.2-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE

## Getting started

1. Add navigation support to the application state by adhering to the `NavigationStateRoot` protocol.
    ```swift
      struct AppState: NavigationStateRoot {
        var navigation: NavigationState = NavigationState()
      }
    ```

1. Add the navigation reducer to the store.
    ```swift
      Store(state: AppState(), reducer: AppReducer() + NavigationReducer())
    ```

1. Wrap your root view with `RootNavigationView`. Then attach any environment objects outside of it. If the environment objects are not injected outside of this view, they may not propagate to all view hierarchies.
    ```swift
      RootNavigationView {
        RootView()
      }.provideStore(store)
    ```

1. Provide the SwiftDux store a second time using the `NavigationStateRoot` protocol. This allows SwiftDuxNavigation's views access it.
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
    Clean up any old scenes by dispatching `NavigationAction.clearScene(named:)`.
    ```swift
    // Inside the AppDelegate
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
      sceneSessions.forEach { session in
        store.dispatch(NavigationAction.clearScene(named: sceneSessions.persistentIdentifier))
      }
    }
    ```

## Navigating the application

### RouteLink
This is similar to a SwiftUI NavigationLink, and can be used just like one. It navigates to a new route relative to the containing view when the user taps it.

```swift
// Pass a single path parameter or component.
let id = 123
RouteLink(path: id) { Text("Label") }

// Go up a level.
RouteLink(path: "..")  { Text("Label") }

// Pass an absolute path.
RouteLink(path: "/person/\(id)/company")  { Text("Label") }

// Navigate the detail route. (when using the SplitNavigationView)
RouteLink(path: id, isDetail: true) { Text("Label") }
```

### CurrentRoute
CurrentRoute is an environment value that provides information about the current route of a view. It can also be used to navigates the application relative to that view's location.

```swift
@MappedDispatch() private var dispatch
Environment(\.currentRoute) private var currentRoute

// Pass a single path parameter or component.
let id = 123
dispatch(currentRoute.navigate(to: id))

// Go up a level.
dispatch(currentRoute.navigate(to: ".."))

// Pass an absolute path.
dispatch(currentRoute.navigate(to: "/person/\(id)/company"))

// Navigate the detail route.
dispatch(currentRoute.navigate(to: id, isDetail: true) { Text("Label") }
```

### NavigationAction
You can use the navigation actions directly if the above options aren't available. It also allows you to navigate by URL. This can be useful if the application has a custom url scheme that launches a new scene for a specific view.

```swift
@MappedDispatch() private var dispatch

// Navigate to a URL. The first path component is the scene's name.
let url = URL(string: "/main/notes")!
dispatch(NavigationAction.navigate(to: url))

// Navigate with a master-detail URL. Use a url fragment to specify the detail route when applicable.
let url = URL(string: "/main/notes#/note/123")!
dispatch(NavigationAction.navigate(to: url)

// Pass a single path parameter or component.
dispatch(NavigationAction.navigate(to: "/notes", inScene: "main"))

// Go up a level.
dispatch(NavigationAction.navigate(to: "..", inScene: "main"))
```

### Route precedence
The precedence of an active route is based on its position in the view hierarchy. In cases where two or more routes share the same parent route, the higher-level route will be chosen. In the following example, the alert route will take precedence over the stack route when the relevant route is set to "display-alert". Any other value will active the stack route instead.
```swift
List {
  ...
}
.stackRoute { id in
  RecipeEditorContainer(id: id)
}
.alertRoute("display-alert") { Alert(title: Text("Hello world!")) }
```

## Stack navigation
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
### Static branching
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
RouteLink(path: "/settings") {
  Text("Settings")
}
```

### Dynamic branching
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
RouteLink(path: "/people/\(person.id)/companies/\(company.id)") {
  Text(Person.fullname)
}
```

## Split navigation
The SplitNavigationView uses UISplitViewController on iOS to display a master-detail interface. Below is an example of a master-detail notes app. The SplitNavigationView automatically handles the expanding and collapsing of the detail route. The root detail route ("/") is ignored when in collapsed mode to provide a placeholder option.

```swift
SplitNavigationView {
  NoteListContainer()
}
.detailRoute {
  // Optional route when no detail view is displayed
  PlaceholderNote()
}
.detailRoute("notes") { noteId in
  NoteEditorContainer(id: noteId)
}
.splitNavigationPreferredDisplayMode(.allVisible)
.splitNavigationShowDisplayModeButton(true)

// Use RouteLink to navigate to a detail route:
RouteLink(path: "notes/\(note.id)", isDetail: true) {
  Text(note.name)
}
```

## Tab navigation
The `TabNavigationView` presents a navigational tab view. It uses the same `View.tabItem` API of the regular TabView. Underneath the hood, each tab is tied to a specific route by name.

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

// Programmatically navigate to a tab route:
currentRoute.navigate(to: "/allMusic")
```