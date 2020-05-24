# SwiftDux Navigation

> Provides deep link routing in SwiftUI applications powered by [SwiftDux](https://github.com/StevenLambion/SwiftDux).

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]

SwiftDux Navigation implements deep-link routing for SwiftUI applications. It's currently in an early development stage.

## Purpose
The purpose of this library is to provide a stateful, deep-link navigational system for an application. In the same way that SwiftUI views represent the application's current state, it does the same for navigation. The library handles this by utilizing a single navigational state object. This state is updated through a reducer function. The changes from the navigational state are then propagated throughout the SwiftUI view hierarchy.

It also provide a small set of primitive navigational views out-of-the-box, but it should not be seen as a UI library. To reduce opinionated UI decisions, it intentionally leaves out platform-specific functionality that may require extra intervention to implement. For example, displaying a right chevron in a navigable list on iOS. Rather than adding extra logic to the `RouteLink` view, it's better for the app developer to implement it the way they see fit. In terms of extensibility, the library should provide everything needed to create new navigational views that it may lack.

## Features
- Route style navigation.
- Navigate by custom URL app scheme.
- Save and restore the navigation via `PersistStateMiddleware`.
- Multi-UIScene support.
- Master-detail routing.
- Automatically passes the store object across view hierarchies.

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
  - Similar API to TabView.
  - Automatically saves and restores tab routes.

## Modals
- `View.sheet(_:content:)` - Displays a sheet by name.
- `View.actionSheet(_:content:)` - Displays an action sheet by name.
- `View.alert(_:content:)` - Displays a an alert by name.

## Extendability

- `RouteReader` - Reads information about the current route and waypoint.
- `WaypointResolver` - Resolves and manages a waypoint for a custom navigational view.

## Environment Values
- `waypoint` - Get information about the current waypoint relative to the view.

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

1. Provide the store to the root of the application.
    ```swift
      RootView().provideStore(store)
    ```

1. Optionally, specify the current scene when creating a new window or UIScene. By default, the routing uses a "main" scene to conduct navigation.
    ```swift
      UIHostingController(
        rootView: SecondaryView().scene(session.persistentIdentifier)
      )
    ```
    Clean up any old scenes by dispatching `NavigationAction.clearScene(_:)`.
    ```swift
    // Inside the AppDelegate
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
      sceneSessions.forEach { session in
        store.dispatch(NavigationAction.clearScene(sceneSessions.persistentIdentifier))
      }
    }
    ```
## Terminology
The library uses specific terminology for the different parts of navigation. Below shows the navigational structure of a notes app. It's broken up into three types of components:
* __Routes__ - Navigational paths within the application.  The notes app has 4 possible routes:
  - "/"
  - "/settings"
  - "/notes"
  - "/notes/{id}"
* __Waypoints__ - Individual destinations within a route. A route is made up of 2 or more waypoints. The last waypoint is its own destination. Each screen in the notes app represents a single waypoint.
* __Legs__ - Segments that connect one waypoint to another within a route.

<div style="text-align:center">
  <img src="Images/terminology.png" width="900"/>
</div>

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

### Waypoint
A waypoint is a single destination within a route. Examples of a waypoint might be a screen, window, action sheet, or alert. The last waypoint of an active route is the current destination of the user. You can navigate relative to a waypoint using its `navigate(to:inScene:isDetail:animate:)` method.

```swift
@MappedDispatch() private var dispatch
Environment(\.waypoint) private var waypoint

// Pass a single path parameter or component.
let id = 123
dispatch(waypoint.navigate(to: id))

// Go up a level.
dispatch(waypoint.navigate(to: ".."))

// Pass an absolute path.
dispatch(waypoint.navigate(to: "/person/\(id)/company"))

// Navigate the detail route.
dispatch(waypoint.navigate(to: id, isDetail: true) { Text("Label") }
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
The precedence of an active route path is based on its position in the view hierarchy. In cases where two or more routes share the same parent route, the higher-level route will be chosen. In the following example, the route that displays an alert will take precedence over the stack route when the relevant route path is set to "display-alert". Because the stack item takes a dynamic path parameter, any other value will active it instead.
```swift
List {
  ...
}
.stackItem { id in
  NoteView(id: id)
}
.alert("display-alert") { Alert(title: Text("Hello world!")) }
```

## Stack navigation
Create a new `StackNavigationView` to display the app's navigation as a stack. The `View.stackItem(_:content:)` methods create the next item in the stack. Think of them as a UIViewController in a UINavigationController.

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
  .stackItem { id in
    ItemDetails(id: id)
  }
}
```
### Static branching
To add multiple branches to a route, use the `View.branch(_:isDefault:)` method. This gives the branches a name to specify the active one. Think of it as the `View.tag(_:)` method for a `TabView`. In cases where a branch isn't specified, the application can redirect to a default one.

```swift
StackNavigationView {
  AppSectionList()
    .stackItem("company") {
      CompanyDetails()
    }
    .stackItem("contact") {
      ContactDetails()
    }
    .stackItem("settings") {
      Settings()
    }
}

// In a view: 
RouteLink(path: "/settings") {
  Text("Settings")
}
```

### Dynamic branching
Dynamic stack items pass their last path component to their contents as a path parameter. Like static stack items, they may have an optional name.

```swift
StackNavigationView {
  List {
    ForEach(items) { item in
      RouteLink(path: "\(item.id)/companies") {
        PersonRow(item)
      }
    }
  }
  .stackItem { id in
    Overview(id: id)
  }
  .stackItem("contact") { id in
    ContactDetails(id: id)
  }
  .stackItem("companies") { id in
    CompanyDetails(id: id)
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
.detailItem {
  // Optional route when no detail view is displayed
  PlaceholderNote()
}
.detailItem("notes") { noteId in
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
  AllMusicContainer().tabItem("allMusic") {
    Image(systemName: "music.note")
    Text("All Music")
  }
  AlbumsContainer().tabItem("albums") {
    Image(systemName: "rectangle.stack")
    Text("Albums")
  }
  PlaylistsContainer("Aw, no playists.").tabItem("playlists") {
    Image(systemName: "music.note.list")
    Text("Playlists")
  }
}
```

[swift-image]: https://img.shields.io/badge/swift-5.2-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE