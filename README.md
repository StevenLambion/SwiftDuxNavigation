# SwiftDux Navigation

> Provides deep link routing in SwiftUI applications powered by [SwiftDux](https://github.com/StevenLambion/SwiftDux).

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]

SwiftDux Navigation implements deep-link routing for SwiftUI applications. It's currently in an early development stage.

## Purpose
The purpose of this library is to provide a stateful, deep-link navigational system for an application. In the same way that SwiftUI views represent the application's current state, it does the same for navigation. The library implements this through a single navigational state object. This state is updated through a reducer function. The changes from the navigational state are then propagated throughout the SwiftUI view hierarchy.

## Features
- Path-based routing
- Built-in stack, split, and tab navigational views.
- API to build custom navigation views.
- Save and restore the navigation state.
- Multi-UIScene support
- URL deep-link support

## Live example

[Checkout the SwiftDux Todo Example](https://github.com/StevenLambion/SwiftUI-Todo-Example/tree/swiftdux-navigation).

<div style="text-align:center">
  <img src="Images/todolist.png" width="900"/>
</div>

## Getting started

1. Add navigation support to the application state by adhering to the `NavigationStateRoot` protocol.
    ```swift
    struct AppState: NavigationStateRoot {
      var navigation: NavigationState = NavigationState()
    }
    ```

1. Add the `NavigationReducer` and `NavigationMiddleware` to the store.
    ```swift
    Store(
      state: AppState(),
      reducer: AppReducer() + NavigationReducer(),
      middleware: NavigationMiddleware()
    )
    ```

1. You may optionally add the `PersistStateMiddleware` from the SwiftDuxExtras module to save the navigational state.
    ```swift
    Store(
      state: AppState(),
      reducer: AppReducer() + NavigationReducer(),
      middleware: 
        NavigationMiddleware() +
        PersistStateMiddleware(JSONStatePersistor())
    )
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

Navigating with a waypoint can be useful in situations where the route should change by a selection, such as in a list. You can add an action binding that automatically performs navigation through selection. This is useful in master-detail scenarios when the selected row should be highlighted.
```swift
struct Props: Equatable {
  @ActionBinding var selectedId: Int?
}

func map(state: AppState, binder: ActionBinder) -> Props? {
  let selectedId = waypoint.resolveComponent(in: state, isDetail: true, as: Int.self)
  return Props(
    selectedId: binder.bind(selectedId) { id in
      self.waypoint.navigate(to: id, isDetail: true)
    }
  )
}

// On macOS, the List's selection property can be used:
func body(props: Props) -> some View {
  List(selection: props.$selectedId) {
    ForEach(items) { item in
      Text(item.name)
    }
  }
}

// On iOS, we need to manually set it because the selection binding
// is for cell selection in edit mode. We also need to make the props 
// variable modifiable to set the binding value even though selectedId's
// setter doesn't actually mutate the struct.
func body(props: Props) -> some View {
  var props = props
  return List {
    ForEach(items) { item in
      Button(item.name) { props.selectedId = item.path }
      .listRowBackground(props.selectedId == item.id ? Color(white: 0.9) : nil)
    }
  }
}
```

### NavigationAction
You can use the navigation actions directly if the above options aren't available. It also allows you to navigate by URL. This can be useful if the application has a custom URL scheme that launches a new scene for a specific view.

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
You can add multiple branches to a route. If a path parameter isn't accepted, they will simply match the route's path component to their name. The first matching branch will be displayed.

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
    ForEach(companies) { company in
      RouteLink(path: "companies/\(company.id)") {
        PersonRow(item)
      }
    }
  }
  .stackItem("stocks") { id in
    StocksOverviewContainer(id: id)
  }
  .stackItem("news") { id in
    NewsFeedContainer(id: id)
  }
  .stackItem("companies") { id in
    CompanyOverviewContainer(id: id)
  }
}

// In a view somewhere else: 
RouteLink(path: "/news/\(newsFeed.id)") {
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
  PlaylistsContainer().tabItem("playlists") {
    Image(systemName: "music.note.list")
    Text("Playlists")
  }
}
```

## Custom navigational view
The `WaypointResolver` is the primary mechanism to build a new navigational view. There's also the `WaypointResolverView` and `WaypointResolverViewModifier` as conveniences. The resolver requires the name of the waypoint and whether or not it should handle a dynamic path parameter. Waypoints may have either a name, a dynamic path parameter, or both.

They use this information to watch the current routing of the application. Their name and dynamic path parameter become segments within the expected path of the route. The `WaypointResolver` will provide information to its contents such as when it becomes active.

The resolver will also notify the routing system that navigation has completed if it happens to be the final destination. This indicates that all waypoints were properly resolved. If a route ever fails to complete, the `NavigationMiddleware` will redirect back to the root of the application. This is the default functionality, and can be overridden.

1. As a basic example, we'll create a new tab-based navigation view. Add the `WaypointResolver` to the body of the view.
    ```Swift
    struct MyTabNavigationView: View {

      var body: some View {
        WaypointResolver()
      }
    }
    ```

1. Because the tab view needs a dynamic path parameter, let's enable it. We should also have a default tab selected. The resolver allows you to specify a default path parameter value. A name for the waypoint isn't specified because we'll just use the path parameter to represent the tab navigation.
    ```Swift
    struct MyTabNavigationView: View {
      var initialTab: String

      var body: some View {
        WaypointResolver(
          hasPathParameter: true, 
          defaultPathParameter: initialTab
        )
      }
    }
    ```

1. Let's implement a new function that handles the results of the resolver. We also need to provide the tab view's contents, so we'll add another variable called `content`. Add an init method to allow the content to be built with a `ViewBuilder`.
    ```Swift
    struct MyTabNavigationView<Content>: View where Content: View {
      var initialTab: String
      var content: Content

      init(initialTab: String, @ViewBuilder content: () -> Content) {
        self.initialTab = initialTab
        self.content = content()
      }

      var body: some View {
        WaypointResolver(
          name: name,
          hasPathParameter: true,
          defaultPathParameter: initialTab,
          content: waypointContents
        )
      }

      func waypointContents(info: ResolvedWaypointInfo) -> some View {
        TabView { content }
      }
    }
    ```

1. Let's add support for tab selection. The resolver gives us the path parameter to use for the selection, so we just need a binding. Add a new function that takes a waypoint and the path parameter to create that new binding. We also include a mapped dispatch function, so we can send a navigation action to the store.
    ```Swift
    // Add this line to dispatch the navigation actions.
    @MappedDispatch() private var dispatch

    /// ...

    private func selection(with waypoint: Waypoint, pathParameter: String) -> Binding<String> {
      Binding(
        get: { pathParameter },
        set: { nextPathParameter in
          self.dispatch(waypoint.navigate(to: nextPathParameter, animate: false))
        }
      )
    }
    ```

1. We call the new method to get the selection binding using `info.waypoint` and `info.pathParameter`. This waypoint represents the tab navigation view itself.
    ```Swift
    func waypointContents(info: ResolvedWaypointInfo) -> some View {
      let selection = selectionBinding(with: info.waypoint, pathParameter: info.pathParameter ?? initialTab)
      return TabView(selection: selection) { content }
    }
    ```
1. The last requirement is to pass down the next waypoint to its children. The `info.nextWaypoint` is extended from `info.waypoint` by including the path parameter. Child waypoints will use it as a starting point for their own route.
    ```Swift
    func waypointContents(info: ResolvedWaypointInfo) -> some View {
      let selection = selectionBinding(with: info.waypoint, pathParameter: info.pathParameter ?? initialTab)
      return TabView(selection: selection) { 
        content.waypoint(with: info.nextWaypoint)
      }
    }
    ```
1. As an extra feature, you may want to cache each tab's route. This allows a user to switch between them without losing their place. You can do this with a simple action in an `onAppear` closure.
    ```swift
    TabView(selection:selection) {
      content.waypoint(with: info.nextWaypoint)
    }
    .onAppear {
      dispatch(info.waypoint.beginCaching())
    }
    ```

1. Here's the completed code for a simple tab navigation view:
    ```Swift
    struct MyTabNavigationView<Content>: View where Content: View {
      @MappedDispatch() private var dispatch
      
      var initialTab: String
      var content: Content

      init(initialTab: String, @ViewBuilder content: () -> Content) {
        self.initialTab = initialTab
        self.content = content()
      }

      var body: some View {
        WaypointResolver(
          hasPathParameter: true,
          defaultPathParameter: initialTab,
          content: waypointContents
        )
      }

      func waypointContents(info: ResolvedWaypointInfo) -> some View {
        let selection = selectionBinding(with: info.waypoint, pathParameter: info.pathParameter ?? initialTab)
        return TabView(selection:selection) {
          content.waypoint(with: info.nextWaypoint)
        }
        .onAppear {
          dispatch(info.waypoint.beginCaching())
        }
      }

      private func selectionBinding(with waypoint: Waypoint, pathParameter: String) -> Binding<String> {
        Binding(
          get: { pathParameter },
          set: { nextPathParameter in
            self.dispatch(waypoint.navigate(to: nextPathParameter, animate: false))
          }
        )
      }
    }
    ```

[swift-image]: https://img.shields.io/badge/swift-5.2-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20%7C%20macOS%2010.15%20%7C%20tvOS%2013%20%7C%20watchOS%206-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE