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
    
    public var StandaloneZones = Zones()
    public var Active: Bool = false
   
    @AppStorage("outerGaps") var outerGaps: Double = 4
    @AppStorage("innerGaps") var innerGaps: Double = 8
    @AppStorage("onTop") var onTop: Bool = true
    
    init() {}
    
    private func getUsableSpace() -> NSRect {
        let frame = (NSScreen.main?.frame)
        let vis = (NSScreen.main?.visibleFrame)
        
        // todo: isMenuBar hidden; return frame, else return vis
        
        let size = vis?.size ?? frame!.size
        let origin = vis?.origin ?? frame!.origin
    
        return NSRect(origin: origin, size: size)
    }
    
    private func getBarHeight() -> CGFloat {
        let frame = (NSScreen.main?.frame)
        let vis = (NSScreen.main?.visibleFrame)
        let barHeight = (frame?.size.height ?? 0) - (vis?.size.height ?? 0) + (vis?.origin.y ?? 0)
        
        return barHeight
    }
    
    private func createWindow() {
        self.window = NSWindow(
            contentRect: getUsableSpace(),
                styleMask: [],
            backing: .buffered, defer: false)
        
        self.window.isReleasedWhenClosed = false
        self.window.canHide = true
        
        self.window?.contentView = NSHostingView(rootView: SwiftUIView(zones: StandaloneZones))

        self.window?.styleMask.remove(.titled)
        self.window?.isMovableByWindowBackground = false
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor(cgColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0))
    }
    
    func checkForHit(point: CGPoint) {
        for i in 0...self.StandaloneZones.zones.count - 1 {
            if self.StandaloneZones.zones[i].Within(point) {
                self.selectedZones.append(self.StandaloneZones.zones[i])
                self.StandaloneZones.zones[i].Hovered = true
                return
            }
        }
    }
    
    public func SplitZone(_ index: Int, splitType: String = "verticle") {
        var zoneIndex = index
        if index < 0 {
            zoneIndex = self.StandaloneZones.zones.count + index
        }
        
        if (splitType == "verticle") {
            self.StandaloneZones.zones[zoneIndex].Size.height -= innerGaps
            self.StandaloneZones.zones[zoneIndex].Size.height /= 2
            
            var dupe = Zone(self.StandaloneZones.zones[zoneIndex].Size, self.StandaloneZones.zones[zoneIndex].Position)
            dupe.Position.y += dupe.Size.height + innerGaps
            self.StandaloneZones.zones.insert(dupe, at: zoneIndex)
        } else if splitType == "horizontal" {
            
        }
    }

    public func GenerateZones(_ targetColumns: Int) {
        self.StandaloneZones = Zones()
        
        let usableSpace = getUsableSpace()
        let screen = usableSpace.size
        
        var width = screen.width
        width -= outerGaps * 2
        width += innerGaps
        
        var height = screen.height
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
        
        for _ in 0...targetColumns - 1 {
            let z = Zone(smartSize, pos)
            self.StandaloneZones.zones.append(z)
            pos.x += smartSize.width + innerGaps
        }
    }
    
    public func AutoGenerateZones() {
        let space = getUsableSpace()
        let columns = Int(ceil(space.size.width / 1280))
    
        self.GenerateZones(columns)
    }
    
    public func Handle(_ cursorPosition: CGPoint) {
        if self.Active == false {
            self.Active = true
            self.createWindow()
            self.window.makeKeyAndOrderFront(nil)
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
        }
        
        
        // reset hovered state
        for i in 0...self.StandaloneZones.zones.count - 1 {
            self.StandaloneZones.zones[i].Hovered = false
        }
        
        self.selectedZones = [Zone]()
        
        // suggest a zone
        checkForHit(point: cursorPosition)
        
        if self.selectedZones.count == 0 {
            for x in [-innerGaps, 0, innerGaps] {
                for y in [-innerGaps, 0, innerGaps] {
                    if x == 0 && y == 0 {
                        continue
                    }
                    
                    checkForHit(point: CGPoint(x: cursorPosition.x - x, y: cursorPosition.y - y))
                }
            }
        }
    }
    
    public func Submit() {
        guard let w = self.currentWindow else { return }
        
        if self.selectedZones.count == 0 {
            return
        }
        
        if self.selectedZones.count == 1 {
            try! w.setAttribute(.position, value: self.selectedZones[0].Position)
            try? w.setAttribute(.size, value: self.selectedZones[0].Size)
        }
        
        let zone = self.selectedZones[0]
        var r = CGRect(origin: zone.Position, size: zone.Size)
        
        for i in 0...self.selectedZones.count - 1 {
            let zone = self.selectedZones[i]
            r = r.union(CGRect(origin: zone.Position, size: zone.Size))
        }
        
        r.origin.y += getBarHeight()
        
        try! w.setAttribute(.position, value: r.origin)
        try? w.setAttribute(.size, value: r.size)
    }
    
    public func Cancel() {
//        self.window.orderOut(self)
        self.window.close()
        
        self.Active = false
        self.currentWindow = nil
        self.selectedZones = [Zone]()
    }
}
