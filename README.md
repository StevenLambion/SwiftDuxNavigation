# SwiftDuxRouting (Experimental)

> An experimental library to implement routing for SwiftDux.

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]

Originally, I hadn't planned on creating a routing library for SwiftDux, but after the lack of features and a number of defects with the built-in offerings I took a stab at what it might take to implement a deep-link style API for SwiftUI.

This library is currently experimental and could be superseded by any new offering Apple might bring along.

## Features
- Deep link style navigation.
- Save and restore the application's navigation using SwiftDux.
- Stack navigation (using UINavigationController)
    - Supports swiping to go back.
    - Works with SwiftUI navigation bar features.
- Scene support (such as UIScene)

## Thing to do
- macOS support
- SplitView support
- TabView support
- Make swipe navigation optional.

[swift-image]: https://img.shields.io/badge/swift-5.2-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE

## Example

### Basic Example
```swift
StackNavigationView {
  List {
    ForEach(items) { item
      RouteLink(path: item.id) {
        Text(item.name)
      }
    }
  }.addRoute { id
    ItemDetails(id: id)
  }
}
```