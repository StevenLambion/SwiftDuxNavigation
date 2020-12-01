import Foundation
import SwiftDux
import SwiftUI

@propertyWrapper
public struct WaypointParameter<T>: DynamicProperty where T: LosslessStringConvertible & Hashable & Equatable {
  @Environment(\.waypoint) private var waypoint

  private var parameter: Binding<T?>?

  public var wrappedValue: T? {
    parameter?.wrappedValue
  }

  public var projectedValue: Binding<T?> {
    Binding(
      get: { parameter?.wrappedValue },
      set: { value in
        if let value = value {
          parameter?.wrappedValue = value
        }
      }
    )
  }

  public init() {}

  public mutating func update() {
    self.parameter = waypoint.destination(as: T.self)
  }
}
