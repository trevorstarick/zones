//
//  Handler.swift
//  fancyzone
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
   
    
    private let padding = 16.0
    
    init() {}
    
    private func createWindow() {
        self.window = NSWindow(
            contentRect: NSRect(origin: CGPoint(x: 0, y: 0), size: (NSScreen.main?.frame.size)!),
                styleMask: [],
                backing: .buffered, defer: false)
        self.window.center()
        
        self.window.isReleasedWhenClosed = false
        self.window.canHide = true
        
        self.window?.contentView = NSHostingView(rootView: SwiftUIView(zones: StandaloneZones))

        self.window?.styleMask.remove(.titled)
        self.window?.isMovableByWindowBackground = true
        
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
    
    func splitZone(_ index: Int, splitType: String = "verticle") {
        var zoneIndex = index
        if index < 0 {
            zoneIndex = self.StandaloneZones.zones.count + index
        }
        
        if (splitType == "verticle") {
            self.StandaloneZones.zones[zoneIndex].Size.height -= padding
            self.StandaloneZones.zones[zoneIndex].Size.height /= 2
            
            var dupe = Zone(self.StandaloneZones.zones[zoneIndex].Size, self.StandaloneZones.zones[zoneIndex].Position)
            dupe.Position.y += dupe.Size.height + padding
            self.StandaloneZones.zones.insert(dupe, at: zoneIndex)
        } else if splitType == "horizontal" {
            
        }
    }

    public func GenerateZones(_ targetColumns: Int) {
        self.StandaloneZones = Zones()
        
        let screen = NSScreen.main!.frame
        let menuBarHeight = (NSApplication.shared.mainMenu?.menuBarHeight)!
        
        let targetWidth = (screen.width - padding) / CGFloat(targetColumns)
        let targetHeight = screen.height - menuBarHeight - padding
        let smartSize = CGSize(
            width: targetWidth - padding,
            height: targetHeight - padding
        )
        
        for i in 0...targetColumns - 1 {
            let pos = CGPoint(
                x: CGFloat(i) * targetWidth + padding,
                y: menuBarHeight + padding
            )
            let z = Zone(smartSize, pos)
            self.StandaloneZones.zones.append(z)
        }
        
//        splitZone(-2)
        splitZone(-1)
    }
    
    public func Handle(_ cursorPosition: CGPoint) {
        if self.Active == false {
            self.Active = true
            self.createWindow()
            self.window.makeKeyAndOrderFront(nil)
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
        
        // reset hovered state
        for i in 0...self.StandaloneZones.zones.count - 1 {
            self.StandaloneZones.zones[i].Hovered = false
        }
        
        self.selectedZones = [Zone]()
        
        // suggest a zone
        checkForHit(point: cursorPosition)
        
        if self.selectedZones.count == 0 {
            checkForHit(point: CGPoint(x: cursorPosition.x - padding, y: cursorPosition.y - padding))
            checkForHit(point: CGPoint(x: cursorPosition.x, y: cursorPosition.y - padding))
            checkForHit(point: CGPoint(x: cursorPosition.x + padding, y: cursorPosition.y - padding))
            
            checkForHit(point: CGPoint(x: cursorPosition.x - padding, y: cursorPosition.y))
//            checkForHit(point: CGPoint(x: cursorPosition.x, y: cursorPosition.y))
            checkForHit(point: CGPoint(x: cursorPosition.x + padding, y: cursorPosition.y))
            
            checkForHit(point: CGPoint(x: cursorPosition.x - padding, y: cursorPosition.y + padding))
            checkForHit(point: CGPoint(x: cursorPosition.x, y: cursorPosition.y + padding))
            checkForHit(point: CGPoint(x: cursorPosition.x + padding, y: cursorPosition.y + padding))
        }

    }
    
    public func Submit() {
        guard let w = self.currentWindow else { return }
        
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
