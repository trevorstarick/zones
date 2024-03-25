//
//  Handler.swift
// zones
//
//  Created by Trevor Starick on 2021-11-22.
//

import Foundation
import AXSwift
import SwiftUI

public class Handler {
    private var currentWindow: UIElement?
    private var window: NSWindow!
    private var selectedZones = [Zone]()
    
    private var lastDisplayID: CGDirectDisplayID = 0
    
    public var StandaloneZones: [CGDirectDisplayID: Zones] = [:]
    public var Active: Bool = false
   
    @AppStorage("outerGaps") var outerGaps: Double = 4
    @AppStorage("innerGaps") var innerGaps: Double = 8
    @AppStorage("onTop") var onTop: Bool = true
    
    init() {}
    
    private func createWindow(screen: NSScreen) {
        self.window = NSWindow(
            contentRect: screen.visibleFrame,
                styleMask: [],
            backing: .buffered, defer: false)
        
        self.window.isReleasedWhenClosed = false
        self.window.canHide = true
        
        self.window?.contentView = NSHostingView(rootView: SwiftUIView(zones: self.StandaloneZones[screen.displayID!]!))
        
        self.window?.styleMask.remove(.titled)
        self.window?.isMovableByWindowBackground = false
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor(cgColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        
        lastDisplayID = screen.displayID!
    }
    
    func checkForHit(point: CGPoint) -> Bool {
        let screen = getScreenWithMouse()!
        let displayID = screen.displayID!
        
        let zones = self.StandaloneZones[displayID]!.zones
        for i in 0...zones.count - 1 {
            let zone = self.StandaloneZones[displayID]!.zones[i]
            if zone.Within(point) {
                self.selectedZones.append(zone)
                self.StandaloneZones[displayID]!.zones[i].Hovered = true
                return true
            }
        }
        
        return false
    }
    
    public func SplitZone(_ screen: NSScreen, _ index: Int, splitType: String = "verticle") {
        var zones = self.StandaloneZones[screen.displayID!]
        
        if zones == nil {
            AutoGenerateZones(screen: screen)
            zones = self.StandaloneZones[screen.displayID!]
        }
        
        var zoneIndex = index
        if index < 0 {
            zoneIndex = zones!.zones.count + index
        }
        
        if (splitType == "verticle") {
            zones!.zones[zoneIndex].Size.height -= innerGaps
            zones!.zones[zoneIndex].Size.height /= 2
            
            var dupe = zones!.zones[zoneIndex].Dupe()
            dupe.GlobalOrigin.y += dupe.Size.height + innerGaps
            dupe.ScreenOrigin.y += dupe.Size.height + innerGaps
            self.StandaloneZones[screen.displayID!]!.zones.append(dupe)
            
            
        } else if splitType == "horizontal" {
            
        }
    }

    public func GenerateZones(screen: NSScreen, targetColumns: Int) {
        if self.StandaloneZones[screen.displayID!] == nil {
            self.StandaloneZones[screen.displayID!] = Zones()
        }
        
        var width = screen.visibleFrame.size.width
        width -= outerGaps * 2
        width += innerGaps
        
        var height = screen.visibleFrame.size.height
        height -= outerGaps * 2
        height += innerGaps
        
        var targetWidth = width
        targetWidth /= CGFloat(targetColumns)
        targetWidth -= innerGaps
        
        var targetHeight = height
        targetHeight -= innerGaps
        
        let smartSize = CGSize(
            width: targetWidth,
            height: targetHeight
        )
        
        var pos = CGPoint(
            x: outerGaps,
            y: outerGaps
        )
        
        let deltaHeight = NSScreen.screens.first!.frame.height - screen.frame.height
        let barHeight = screen.frame.height - screen.visibleFrame.height
    
        
        for _ in 0...targetColumns - 1 {
            let x = pos.x + screen.frame.origin.x
            let y = pos.y - screen.frame.origin.y + deltaHeight + barHeight
            
            let glob = CGPoint(x: x, y: y)
            let z = Zone(smartSize, glob, pos)
            self.StandaloneZones[screen.displayID!]!.zones.append(z)
            pos.x += smartSize.width + innerGaps
        }
    }
    
    public func AutoGenerateZones(screen: NSScreen) {
        let columns = Int(ceil(screen.visibleFrame.size.width / 1280))
    
        self.GenerateZones(screen: screen, targetColumns: columns)
    }
    
    public func Handle(_ cursorPosition: CGPoint) {
        let screen = getScreenWithMouse()!
        
        if self.Active == false {
            self.Active = true
            self.createWindow(screen: screen)
            self.window.orderFront(nil)
            if onTop {
                self.window.orderFrontRegardless()
            }
            
            let app = NSWorkspace.shared.frontmostApplication!
            let uiApp = Application(app)!
            
            let windows = try! uiApp.windows()!
            windows.forEach { w in
                let attrFocused: Bool? = try! w.attribute(.focused)
                let attrMain: Bool? = try! w.attribute(.main)
                
                if attrFocused ?? false || attrMain ?? false {
                    self.currentWindow = w
                }
            }
        } else if lastDisplayID != screen.displayID! {
            self.window.close()
            self.createWindow(screen: screen)
            self.window.orderFront(nil)
            if onTop {
                self.window.orderFrontRegardless()
            }
        }
        
        // reset hovered state
        for i in 0...self.StandaloneZones[screen.displayID!]!.zones.count - 1 {
            self.StandaloneZones[screen.displayID!]!.zones[i].Hovered = false
        }
        
        self.selectedZones = [Zone]()
        
        if self.selectedZones.count == 0 {
            for x in [-innerGaps, 0, innerGaps] {
                for y in [-innerGaps, 0, innerGaps] {
                    _ = checkForHit(point: CGPoint(
                        x: cursorPosition.x + x,
                        y: cursorPosition.y + y
                    ))
                }
            }
        }
    }
    
    func normalizePosition(
        origin: CGFloat, padding: CGFloat, weight: CGFloat, 
        max: CGFloat, actual: CGFloat, target: CGFloat
    ) -> CGFloat {
        // if the weight is on the left side
        if (origin + padding > weight) {
            return origin
        } 
        
        // if the weight is on the right side
        if (origin + target - padding < weight) {
            return origin + target - actual
        }
        
        // if the actual size is less than the target size
        if (actual < target) {
            return origin + floor(abs(target - actual) / 2)
        }
        
        // if the actual size is greater than the target size, 
        //  and the actual size is less than the max size, 
        //  and the actual size will not exceed the max size given the origin
        if (actual < max && origin + actual > max) {
            return origin + target - actual
        }

        // otherwise, return the origin as is
        return origin
    }
    
    public func Submit() {
        guard let w = self.currentWindow else { return }
        
        if self.selectedZones.count == 0 {
            return
        }
        
        var r = CGRect(
            origin: self.selectedZones.first!.GlobalOrigin,
            size: self.selectedZones.first!.Size
        )
        
        if self.selectedZones.count > 1 {
            for i in 1...self.selectedZones.count - 1 {
                r = r.union(CGRect(
                    origin: self.selectedZones[i].GlobalOrigin,
                    size: self.selectedZones[i].Size
                ))
            }
        }
        
        try? w.setAttribute(.position, value: r.origin)
        try? w.setAttribute(.size, value: r.size)
        
        let attr = try! w.getMultipleAttributes(.size, .position)
        let size = attr[.size] as! CGSize
        var position = attr[.position] as! CGPoint
        
        let mousePosition = CGPoint(
            x: NSEvent.mouseLocation.x,
            y: (getScreenWithMouse()?.frame.height)! - NSEvent.mouseLocation.y
        )
       
        let percentage = 1.0/8.0
        var padding = 64.0

        position.x = normalizePosition(
            origin: r.origin.x,
            padding: padding,
            weight: mousePosition.x,
            max: (getScreenWithMouse()?.frame.width)!,
            actual: size.width,
            target: r.width
        )

        position.y = normalizePosition(
            origin: r.origin.y,
            padding: padding,
            weight: mousePosition.y,
            max: (getScreenWithMouse()?.frame.height)!,
            actual: size.height,
            target: r.height
        )
        
        // todo: use NSEvent.mouseLocation to move the position to the closest edge(s)
        try? w.setAttribute(.position, value: position)
    }
    
    public func Cancel() {
        self.window.close()
        
        self.Active = false
        self.currentWindow = nil
        self.selectedZones = [Zone]()
    }
}
