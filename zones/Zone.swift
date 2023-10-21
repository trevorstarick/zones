//
//  Zone.swift
// zones
//
//  Created by Trevor Starick on 2021-11-22.
//

import Foundation
import SwiftUI

public class Zones: ObservableObject {
    @Published public var zones = [Zone]()
}

public struct Zone: Identifiable, Hashable {
    public static func == (lhs: Zone, rhs: Zone) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    public var Size: CGSize
    public var Position: CGPoint
    private var origin: CGPoint
    
    public var Hovered: Bool
    
    init(_ rect: CGRect) {
        self.init(rect.size, rect.origin, CGPoint(x: 0, y: 0))
    }
    
    init(_ size: CGSize, _ position: CGPoint, _ origin: CGPoint) {
        Size = size
        Position = position
        Hovered = false
        self.origin = origin
    }
    
    public func Origin() -> CGPoint {
        return CGPoint(
            x: self.Position.x + self.origin.x,
            y: self.Position.y + self.origin.y
        )
    }
    
    public func Dupe() -> Zone {
        return Zone(self.Size, self.Position, self.origin)
    }
    
    public func Within(_ position: CGPoint) -> Bool {
        return (
            self.Position.x <= position.x
            && position.x <= self.Position.x + self.Size.width
            && self.Position.y <= position.y
            && position.y <= self.Position.y + self.Size.height
        )
    }
}
