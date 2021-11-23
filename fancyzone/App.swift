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
    
    init() {}
    
    var body: some Scene {
        WindowGroup {
            HStack {
                Text("a")
                Text("b")
                Spacer()
                Text("c")
            }.padding()
        }
        
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
    var showMenuButton: Bool = true
        
    func applicationDidFinishLaunching(_ notification: Notification) {
        backgroundService()
        
        let menu  = NSMenu()
        let menuItem = NSMenuItem()
        
        let view = NSHostingView(rootView: ContentView())
        view.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
        
        menuItem.view = view
        menu.addItem(menuItem)

        if showMenuButton {
            statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusBarItem?.button?.title = "fz"
            statusBarItem?.menu = menu
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("CleverZones")
                .bold()
            Divider()
            Text("A")
            Text("B")
            Text("C")
            Divider()
            Text("Quit CleverZones")
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
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
