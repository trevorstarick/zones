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
    public var GlobalOrigin: CGPoint
    public var ScreenOrigin: CGPoint
    
    public var Hovered: Bool
    
    init(_ size: CGSize, _ global: CGPoint, _ screen: CGPoint) {
        Size = size
        GlobalOrigin = global
        ScreenOrigin = screen
        Hovered = false
    }
    
    public func Dupe() -> Zone {
        return Zone(self.Size, self.GlobalOrigin, self.ScreenOrigin)
    }
    
    public func Within(_ position: CGPoint) -> Bool {
        let r = CGRect(
            origin: self.GlobalOrigin,
            size: self.Size
        )
        
        return CGRectContainsPoint(r, position)
    }
}
