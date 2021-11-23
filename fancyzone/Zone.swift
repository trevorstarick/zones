//
//  Zone.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-22.
//

import Foundation

class Zone {
    var Size: CGSize
    var Position: CGPoint
    
    var Composite: Bool
    
    init(_ size: CGSize, _ position: CGPoint, _ composite: Bool = false) {
        Size = size
        Position = position
        Composite = composite
    }
    
    init(_ rect: CGRect) {
        Size = rect.size
        Position = rect.origin
        Composite = false
    }
    
    func Within(_ position: CGPoint) -> Bool {
        return (
            self.Position.x <= position.x
            && position.x <= self.Position.x + self.Size.width
            && self.Position.y <= position.y
            && position.y <= self.Position.y + self.Size.height
        )
    }
    
    func Display() {}
}
