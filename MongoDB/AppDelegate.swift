//
//  AppDelegate.swift
//  mongodb
//
//  Created by Giovanni Collazo on 1/15/15.
//  Copyright (c) 2015 Giovanni Collazo. All rights reserved.
//

import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var updater: SUUpdater!
    
    static let userApplicationSupportDirectory =
        try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    var dataPath: String
    var logPath: String
    
    var task: Process = Process()
    var pipe: Pipe = Pipe()
    var file: FileHandle
    
    var statusBar = NSStatusBar.system
    var statusBarItem: NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    
    var statusMenuItem: NSMenuItem = NSMenuItem()
    var openMongoMenuItem: NSMenuItem = NSMenuItem()
    var openLogsMenuItem: NSMenuItem = NSMenuItem()
    var docsMenuItem: NSMenuItem = NSMenuItem()
    var aboutMenuItem: NSMenuItem = NSMenuItem()
    var versionMenuItem: NSMenuItem = NSMenuItem()
    var quitMenuItem: NSMenuItem = NSMenuItem()
    var updatesMenuItem: NSMenuItem = NSMenuItem()
    
    override init() {

        let appSupport = AppDelegate.userApplicationSupportDirectory

        guard
            let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
        else {
            fatalError("Unable to determine application name & version from Info.plist")
        }
        
        // Add name to Application Support directory, then add the version (which follows mongoDB version).
        // A versioned directory allows users to use separate versions of the app without worrying about
        // incompatible data or log file formats.

        let dataDirectory = appSupport
            .appendingPathComponent(appName)

        self.dataPath = dataDirectory.appendingPathComponent("Data").path
        self.logPath = dataDirectory.appendingPathComponent("Logs").path

        self.file = self.pipe.fileHandleForReading

        super.init()
    }
    
    func startServer() {
        self.task = Process()
        self.pipe = Pipe()
        self.file = self.pipe.fileHandleForReading
        
        if let path = Bundle.main.path(forResource: "mongod", ofType: "", inDirectory: "Vendor/mongodb/bin") {
            self.task.launchPath = path
        }
        
        self.task.arguments = [
            "--dbpath", "\(self.dataPath)",
            "--nounixsocket",
            "--bind_ip",
            "127.0.0.1",
            "--logpath", "\(self.logPath)/mongo.log"
        ]
        self.task.standardOutput = self.pipe
        
        print("Run mongod")
        
        self.task.launch()
    }
    
    func stopServer() {
        print("Terminate mongod")
        task.terminate()
        
        let data: Data = self.file.readDataToEndOfFile()
        self.file.closeFile()
        
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        print(output)
    }
    
    @objc func openMongo(_ sender: AnyObject) {
        if let path = Bundle.main.path(forResource: "mongo", ofType: "", inDirectory: "Vendor/mongodb/bin") {
            var source: String
            
            if appExists("iTerm") {
                source = "tell application \"iTerm\" \n" +
                            "activate \n" +
                            "create window with default profile \n" +
                            "tell current session of current window \n" +
                                "write text \"\(path)\" \n" +
                            "end tell \n" +
                        "end tell"
            } else {
                source = "tell application \"Terminal\" \n" +
                            "activate \n" +
                            "do script \"\(path)\" \n" +
                         "end tell"
            }

            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(nil)
            }
        }
    }
    
    @objc func openDocumentationPage(_ send: AnyObject) {
        if let url: URL = URL(string: "https://github.com/gcollazo/mongodbapp") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openLogsDirectory(_ send: AnyObject) {
        NSWorkspace.shared.openFile(self.logPath)
    }
    
    func createDirectories() {
        if (!FileManager.default.fileExists(atPath: self.dataPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.dataPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Something went wrong creating dataPath: \(error)")
            }
        }

        if (!FileManager.default.fileExists(atPath: self.logPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.logPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Something went wrong creating logPath: \(error)")
            }
        }

        print("Mongo data directory: \(self.dataPath)")
        print("Mongo logs directory: \(self.logPath)")
    }
    
    @objc func checkForUpdates(_ sender: AnyObject?) {
        print("Checking for updates")
        self.updater.checkForUpdates(sender)
    }
    
    func setupSystemMenuItem() {
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        
        let icon = NSImage(named: NSImage.Name(rawValue: "leaf"))
        icon!.isTemplate = true
        icon!.size = NSSize(width: 18, height: 16)
        statusBarItem.image = icon
        
        // Add version to menu
        versionMenuItem.title = "MongoDB"
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? {
            versionMenuItem.title = "MongoDB v\(version)"
        }
        menu.addItem(versionMenuItem)
        
        // Add actionMenuItem to menu
        statusMenuItem.title = "Running on Port 27017"
        menu.addItem(statusMenuItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add open mongo to menu
        openMongoMenuItem.title = "Open mongo"
        openMongoMenuItem.action = #selector(AppDelegate.openMongo(_:))
        menu.addItem(openMongoMenuItem)
        
        // Add open logs to menu
        openLogsMenuItem.title = "Open logs directory"
        openLogsMenuItem.action = #selector(AppDelegate.openLogsDirectory(_:))
        menu.addItem(openLogsMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add check for updates to menu
        updatesMenuItem.title = "Check for Updates..."
        updatesMenuItem.action = #selector(AppDelegate.checkForUpdates(_:))
        menu.addItem(updatesMenuItem)

        // Add about to menu
        aboutMenuItem.title = "About"
        aboutMenuItem.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        menu.addItem(aboutMenuItem)
        
        // Add docs to menu
        docsMenuItem.title = "Documentation..."
        docsMenuItem.action = #selector(AppDelegate.openDocumentationPage(_:))
        menu.addItem(docsMenuItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add quitMenuItem to menu
        quitMenuItem.title = "Quit"
        quitMenuItem.action = #selector(NSApplication.shared.terminate)
        menu.addItem(quitMenuItem)
    }
    
    func appExists(_ appName: String) -> Bool {
        let found = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app"
        ].map {
            return FileManager.default.fileExists(atPath: $0)
        }.reduce(false) {
            if $0 == false && $1 == false {
                return false;
            } else {
                return true;
            }
        }

        return found
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createDirectories()
        setupSystemMenuItem()
        startServer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopServer()
    }
    
}

