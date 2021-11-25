//
//  fancyzoneApp.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-21.
//

import SwiftUI
import AXSwift

@main
struct app: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
//        WindowGroup {
//            ZStack {
//              EmptyView()
//            }.hidden()
//        }
        
        WindowGroup("Preferences") { // other scene
            Preferences()
                .handlesExternalEvents(
                    preferring: Set(arrayLiteral: "preferences"),
                    allowing: Set(arrayLiteral: "*")
            ) // activate existing window if exists
        }
        .handlesExternalEvents(
            matching: Set(arrayLiteral: "preferences")
        ) // create new window if one doesn't exist
        
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

func backgroundService() {
    guard UIElement.isProcessTrusted(withPrompt: true) else {
        NSLog("No accessibility API permission, exiting")
        usleep(10000)
        NSRunningApplication.current.terminate()
        return
    }
    
    var leftDown = false
    let handler = Handler()
    handler.GenerateZones(4)
    
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: { event in
        leftDown = true
    })
    
    // check if the position has changed
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: { event in
        if handler.Active {
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
        } else {
            handler.Cancel()
        }
    })
    
    print("fz: ready")
}
