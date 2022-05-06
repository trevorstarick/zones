//
//  fancyzoneApp.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-21.
//

import SwiftUI
import AXSwift

public var handler = Handler()

@main
struct app: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}



struct PrimaryView: View {
    
    var body: some View {
        ZStack {
            EmptyView()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var application: NSApplication = NSApplication.shared
    var statusBarItem: NSStatusItem?
    var showMenuButton: Bool = true
    
    @Environment(\.openURL) var openURL
    @objc func showPreferences(_: Any?) {
       if let url = URL(string: "fancyzones://preferences") {
            openURL(url)
       }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        backgroundService()
        menuService()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func menuService() {        
        let menu  = NSMenu()
        
        let preferences = NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(preferences)
        
        let aboutCleverZones = NSMenuItem(title: "About CleverZones", action: #selector(NSApplication.shared.showHelp), keyEquivalent: "")
        menu.addItem(aboutCleverZones)
        
        menu.addItem(.separator())
        
        let quitCleverZones = NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate), keyEquivalent: "q")
        menu.addItem(quitCleverZones)
        
        if showMenuButton {
            statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusBarItem?.button?.title = "💩"
            statusBarItem?.menu = menu
        }
    }
}

struct Coords {
    var X: Int = 0
    var Y: Int = 0
    
    init(_ x: Int, _ y: Int) {
        X = x
        Y = y
    }
}

func windowNumberToPosition(windowNumber: Int) -> Coords {
    // With this procedure, we get all available windows.
    let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
    let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
    let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]

    // Now that we have all available windows, we are going to check if at least one of them
    // is owned by Safari.
    for info in windowInfoList! {
        if (windowNumber == info["kCGWindowNumber"] as! Int) {
            if (info["kCGWindowBounds"] != nil) {
                let x = (info["kCGWindowBounds"] as! NSDictionary)["X"] as! Int
                let y = (info["kCGWindowBounds"] as! NSDictionary)["Y"] as! Int
                return Coords(x, y)
            }
            
            return Coords(-1, -1)
        }
    }
    
    return Coords(-1, -1)
}

func backgroundService() {
    guard UIElement.isProcessTrusted(withPrompt: true) else {
        NSLog("No accessibility API permission, exiting")
        usleep(10000)
        NSRunningApplication.current.terminate()
        return
    }
    
    var leftDown = false
    handler.GenerateZones(4)
    
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: { event in
        let coords = windowNumberToPosition(windowNumber: event.windowNumber)
        if (Int(event.cgEvent!.location.y) < coords.Y + 38) {
            leftDown = true
        }
        
    })
    
    // check if the position has changed
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: { event in
        if handler.Active || (leftDown && event.modifierFlags.contains(.command)) {
            let coord = CGPoint(
                x: event.locationInWindow.x,
                y: NSScreen.main!.frame.height - event.locationInWindow.y
            )
            handler.Handle(coord)
        }
    })
    
    // if left is still down, and the pos has changed, we're golden; pony boy
    NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown, handler: { event in
        if leftDown {
            let coord = CGPoint(
                x: event.locationInWindow.x,
                y: NSScreen.main!.frame.height - event.locationInWindow.y
            )
            handler.Handle(coord)
        }
    })
    
    // done
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: { event in
        leftDown = false
        
        if handler.Active {
            handler.Submit()
            handler.Cancel()
        }
    })
    
    print("fz: ready")
}
