//
//  Zone.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-22.
//

import Foundation
import SwiftUI

public class Zone: Identifiable, Hashable {
    public static func == (lhs: Zone, rhs: Zone) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    public var Size: CGSize
    public var Position: CGPoint
    
    public var Composite: Bool
    
    convenience init(_ rect: CGRect) {
        self.init(rect.size, rect.origin, false)
    }
    
    init(_ size: CGSize, _ position: CGPoint, _ composite: Bool = false) {
        Size = size
        Position = position
        Composite = composite
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
