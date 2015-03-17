//
//  AppDelegate.swift
//  mongodb
//
//  Created by Giovanni Collazo on 1/15/15.
//  Copyright (c) 2015 Giovanni Collazo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)
    
    var documentsDirectory: AnyObject
    var dataPath: String
    
    var task: NSTask = NSTask()
    var pipe: NSPipe = NSPipe()
    var file: NSFileHandle
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem: NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    
    var statusMenuItem: NSMenuItem = NSMenuItem()
    var openMongoMenuItem: NSMenuItem = NSMenuItem()
    var docsMenuItem: NSMenuItem = NSMenuItem()
    var aboutMenuItem: NSMenuItem = NSMenuItem()
    var versionMenuItem: NSMenuItem = NSMenuItem()
    var quitMenuItem: NSMenuItem = NSMenuItem()
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0]
        self.dataPath = documentsDirectory.stringByAppendingPathComponent("MongoData")
        
        super.init()
    }
    
    func startServer() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading
        
        if let path = NSBundle.mainBundle().pathForResource("mongod", ofType: "", inDirectory: "Vendor/mongodb"){
            self.task.launchPath = path
        }
        
        self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket"]
        self.task.standardOutput = self.pipe
        
        println("Run mongod")
        
        self.task.launch()
    }
    
    func stopServer() {
        println("Terminate mongod")
        task.terminate()
        
        let data: NSData = self.file.readDataToEndOfFile()
        self.file.closeFile()
        
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
        println(output)
    }
    
    func openMongo(sender: AnyObject) {
        if let path = NSBundle.mainBundle().pathForResource("mongo", ofType: "", inDirectory: "Vendor/mongodb"){
            let source = "tell application \"Terminal\" to do script \"\(path)\""
            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(nil)
            }
        }
    }
    
    func openDocumentationPage(send: AnyObject) {
        if let url: NSURL = NSURL(string: "https://github.com/gcollazo/mongodbapp") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    func createDataDirectory() {
        println("Create data directory")
        var error: NSError?
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.dataPath)) {
            NSFileManager.defaultManager().createDirectoryAtPath(self.dataPath,
                withIntermediateDirectories: false, attributes: nil, error: &error)
        }
        println("Mongo data directory: \(self.dataPath)")
    }
    
    func setupSystemMenuItem() {
        // Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        
        var icon = NSImage(named: "leaf")
        icon?.size = NSSize(width: 18, height: 16)
        icon?.setTemplate(true)
        statusBarItem.image = icon
        
        // Add actionMenuItem to menu
        statusMenuItem.title = "Running on Port 27017"
        menu.addItem(statusMenuItem)
        
        // Add version to menu
        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String? {
            versionMenuItem.title = "MongoDB v\(version)"
            menu.addItem(versionMenuItem)
        }
        
        // Add separator
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add open mongo to menu
        openMongoMenuItem.title = "Open mongo"
        openMongoMenuItem.action = Selector("openMongo:")
        menu.addItem(openMongoMenuItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add about to menu
        aboutMenuItem.title = "About"
        aboutMenuItem.action = Selector("orderFrontStandardAboutPanel:")
        menu.addItem(aboutMenuItem)
        
        // Add docs to menu
        docsMenuItem.title = "Documentation..."
        docsMenuItem.action = Selector("openDocumentationPage:")
        menu.addItem(docsMenuItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add quitMenuItem to menu
        quitMenuItem.title = "Quit"
        quitMenuItem.action = Selector("terminate:")
        menu.addItem(quitMenuItem)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        createDataDirectory()
        setupSystemMenuItem()
        startServer()
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        stopServer()
    }
    
}

