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
    var actionMenuItem: NSMenuItem = NSMenuItem()
    var statusMenuItem: NSMenuItem = NSMenuItem()
    var connectionMenuItem: NSMenuItem = NSMenuItem()
    var quitMenuItem: NSMenuItem = NSMenuItem()
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0]
        self.dataPath = documentsDirectory.stringByAppendingPathComponent("MongoData")
        
        super.init()
    }
    
    func toggleServerState(sender: AnyObject) {
        if self.task.running {
            stopServer()
            self.actionMenuItem.title = "Start Server"
            self.statusMenuItem.title = "Status: Server not running"
        } else {
            startServer()
            self.actionMenuItem.title = "Stop Server"
            self.statusMenuItem.title = "Status: Server is running"
        }
    }
    
    func startServer() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading
        
        if let path = NSBundle.mainBundle().pathForResource("mongod", ofType: "", inDirectory: "Vendor/mongodb"){
            self.task.launchPath = path
        }
        
        self.task.arguments = ["--dbpath", self.dataPath]
        self.task.standardOutput = self.pipe
        
        println("Run mongod")
        
        // Send notification
        var notification = NSUserNotification()
        notification.title = "MongoDB"
        notification.subtitle = "Server is running"
        var center = NSUserNotificationCenter.defaultUserNotificationCenter()
        center.scheduleNotification(notification)
        
        self.task.launch()
    }
    
    func stopServer() {
        println("Terminate mongod")
        task.terminate()
        
        let data: NSData = self.file.readDataToEndOfFile()
        self.file.closeFile()
        
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
        println(output)
        
        // Send notification
        var notification = NSUserNotification()
        notification.title = "MongoDB"
        notification.subtitle = "Server is not running"
        var center = NSUserNotificationCenter.defaultUserNotificationCenter()
        center.scheduleNotification(notification)
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
        icon?.size = NSSize(width: 10, height: 16)
        icon?.setTemplate(true)
        statusBarItem.image = icon
        
        // Add actionMenuItem to menu
        actionMenuItem.title = "Start"
        actionMenuItem.action = Selector("toggleServerState:")
        menu.addItem(actionMenuItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add statusMenuItem to menu
        statusMenuItem.title = "Status: Server not running"
        menu.addItem(statusMenuItem)
        
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
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        if self.task.running {
            stopServer()
        }
    }
    
}

