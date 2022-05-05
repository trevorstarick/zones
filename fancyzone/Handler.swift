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
    private var selectedZone: Zone?
    private var window: NSWindow!
    
    public var Zones = [Zone]()
    public var Active: Bool = false
    
    init() {}
    
    private func createWindow() {
        self.window = NSWindow(
            contentRect: NSRect(origin: CGPoint(x: 0, y: 0), size: (NSScreen.main?.frame.size)!),
                styleMask: [],
                backing: .buffered, defer: false)
        self.window.center()
        
        self.window.isReleasedWhenClosed = false
        self.window.canHide = true
        
        self.window?.contentView = NSHostingView(rootView: SwiftUIView())

        self.window?.styleMask.remove(.titled)
        self.window?.isMovableByWindowBackground = true
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor(cgColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0))
    }

    public func GenerateZones(_ targetColumns: Int) {
        self.Zones = [Zone]()
        
        let screen = NSScreen.main!.frame
        let padding = 16.0
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
            self.Zones.append(z)
        }
        
        // todo: generate merged zones and make the largest ones at the bottom of the zone array
        // todo: order and break on zone matching
        // todo: generate zones based on a percentage or something
        // todo: zones be display specific
        
        // generate solo zones
        self.Zones.forEach{ zone in
            self.Zones = [
                Zone(CGSize(width: 1260.0, height: 1384.0), CGPoint(x: 16.0, y: 40.0)),
                Zone(CGSize(width: 1260.0, height: 1384.0), CGPoint(x: 1292.0, y: 40.0)),
                Zone(CGSize(width: 1260.0, height: 1384.0), CGPoint(x: 2568.0, y: 40.0)),
                
                Zone(CGSize(width: 1260.0, height: 684.0), CGPoint(x: 3844.0, y: 40.0)),
                Zone(CGSize(width: 1260.0, height: 684.0), CGPoint(x: 3844.0, y: 740.0))
            ]
        }
        
        // generate overlap zones
        for i in 0...Zones.count - 2 {
            let zoneA = Zones[i]
            let zoneB = Zones[i+1]
            
            let width = zoneB.Position.x + zoneB.Size.width - zoneA.Position.x
            let height = max(zoneA.Size.height, zoneB.Size.height)
            let size = CGSize(width: width, height: height)
            self.Zones.append(Zone(size, self.Zones[i].Position, true))
        }
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
        
        if self.selectedZone != nil {
            if self.selectedZone!.Composite {
                self.selectedZone = nil
            } else if self.selectedZone!.Within(cursorPosition) {
                return
            } else {
                self.selectedZone = nil
            }
        }
        
        // todo: display zones here
        
        // suggest a zone
        for i in 0...self.Zones.count - 1 {
            let zone = self.Zones[i]
            if zone.Within(cursorPosition) {
                self.selectedZone = zone
                break
            }
        }
        
        if self.selectedZone == nil {
            // todo: calculate if something should be in between two zones
        }

    }
    
    public func Submit() {
        guard let w = self.currentWindow else { return }
        guard let z = self.selectedZone else {return }
        
        try! w.setAttribute(.position, value: z.Position)
        try? w.setAttribute(.size, value: z.Size)
    }
    
    public func Cancel() {
        print("a")
//        self.window.orderOut(self)
        self.window.close()
        
        self.Active = false
        self.currentWindow = nil
        self.selectedZone = nil
    }
}
