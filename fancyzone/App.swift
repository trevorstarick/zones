//
//  fancyzoneApp.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-21.
//

import SwiftUI
import AXSwift

public var handler = Handler()

var leftDown = false
var toggled = false

@main
struct app: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            Preferences()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var application: NSApplication = NSApplication.shared
    var statusBarItem: NSStatusItem?
    var showMenuButton: Bool = true
    
    @Environment(\.openURL) var openURL
    @objc func showPreferences(_: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    
    func equals(_ x : Any, _ y : Any) -> Bool {
        guard x is AnyHashable else { return false }
        guard y is AnyHashable else { return false }
        return (x as! AnyHashable) == (y as! AnyHashable)
    }

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            usleep(10000)
            NSRunningApplication.current.terminate()
            return
        }

        genZones()
        
        var state: [String: Any] = UserDefaults.standard.dictionaryRepresentation()
        
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: OperationQueue.main) {
                notification -> Void in
                let newState = UserDefaults.standard.dictionaryRepresentation()
                
                var doGenZone = false
                
                for (key, value) in state {
                    if newState[key] == nil {
                        
                    } else if !self.equals(value, newState[key]!) {
                        if [
                            "outerGaps",
                            "innerGaps",
                            "onTop",
                            "splitLast",
                            "columns"
                        ].contains(key) {
                            doGenZone = true
                        } else {
                            print("\(key): \(value) -> \(newState[key]!)")
                        }
                    }
                }
                
                if doGenZone {
                    genZones()
                }
                
                state = newState
            }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: OperationQueue.main) {
                notification -> Void in
                genZones()
            }
        
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

func windowNumberToPosition(windowNumber: Int) -> CGRect {
    let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
    let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
    let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
    
    for info in windowInfoList! {
        if (windowNumber == info["kCGWindowNumber"] as! Int) {
            if (info["kCGWindowBounds"] != nil) {
                let x = (info["kCGWindowBounds"] as! NSDictionary)["X"] as! Int
                let y = (info["kCGWindowBounds"] as! NSDictionary)["Y"] as! Int
                let width = (info["kCGWindowBounds"] as! NSDictionary)["Width"] as! Int
                let height = (info["kCGWindowBounds"] as! NSDictionary)["Height"] as! Int
                
                return CGRect(x: x, y: y, width: width, height: height)
            }
            
            return CGRect()
        }
    }
    
    return CGRect()
}

func activate(_ event: NSEvent) {
    toggled = true
    let coord = CGPoint(
        x: event.locationInWindow.x,
        y: NSScreen.main!.frame.height - event.locationInWindow.y
    )
    handler.Handle(coord)
}

func cancel() {
    toggled = false
    
    if handler.Active {
        handler.Cancel()
    }
}

func genZones() {
    @AppStorage("splitLast") var splitLast: Bool = true
    @AppStorage("columns") var columns: Int = 0
    
    if columns > 0 {
        handler.GenerateZones(columns)
    } else {
        handler.AutoGenerateZones()
    }
    
    if handler.StandaloneZones.zones.count > 1 && splitLast {
        handler.SplitZone(-1)
    }
}

func backgroundService() {
    var hoverEvent: NSEvent?
    
    // timer that updates the current position (hover)
    _ = Timer.scheduledTimer(withTimeInterval: 1.0/20.0, repeats: true) { timer in
        if hoverEvent != nil {
            activate(hoverEvent!)
            hoverEvent = nil
        }
    }
    
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: { event in
        let coords = windowNumberToPosition(windowNumber: event.windowNumber)
        
        if coords.minY > 0 && coords.contains(event.cgEvent!.location) && CGFloat(event.cgEvent!.location.y) < coords.minY + 38 {
            leftDown = true
        }
        
    })
    
    NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: { event in
        if (event.keyCode == 54 || event.keyCode == 55) {
            if event.modifierFlags.contains(.command) {
                // key down
                if toggled {
                    cancel()
                    return
                } else if leftDown {
                    activate(event)
                }
            } else {
                // key up
            }
        }
    })
    
    // check if the position has changed
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: { event in
        if handler.Active && hoverEvent == nil {
            hoverEvent = event
        }
    })
    
    // if left is still down, and the pos has changed, we're golden; pony boy
    NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown, handler: { event in
        if leftDown {
            if toggled {
                cancel()
                return
            }

            activate(event)
        }
    })
    
    // done
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: { event in
        if leftDown {
            leftDown = false
            toggled = false
            hoverEvent = nil
            
            if handler.Active {
                handler.Submit()
                handler.Cancel()
            }
        }
    })
    
    print("fz: ready")
}
