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
    @IBOutlet weak var updater: SUUpdater!
    
    var paths = NSSearchPathForDirectoriesInDomains(
        FileManager.SearchPathDirectory.documentDirectory,
        FileManager.SearchPathDomainMask.userDomainMask, true)
    
    var documentsDirectory: AnyObject
    var dataPath: String
    var logPath: String
    var bindIp: String
    
    var task: Process = Process()
    var pipe: Pipe = Pipe()
    var file: FileHandle
    
    var statusBar = NSStatusBar.system()
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
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0] as AnyObject
        self.dataPath = documentsDirectory.appendingPathComponent("MongoData")
        self.logPath = documentsDirectory.appendingPathComponent("MongoData/Logs")
        self.bindIp = "127.0.0.1"
        super.init()
        
        // Check for ~/.mongodb.conf file and override existing values
        if self.configurationFileExists(){
            let configurationOptions = self.configurationFileDefinitions()
            if let dbPath = configurationOptions["storage.dbPath"]{
                self.dataPath = dbPath
            }
            if let logPath = configurationOptions["systemLog.path"]{
                self.logPath = logPath
            }
            if let bindIp = configurationOptions["net.bindIp"]{
                self.bindIp = bindIp
            }
        }
    }
    
    func startServer() {
        self.task = Process()
        self.pipe = Pipe()
        self.file = self.pipe.fileHandleForReading
        
        if let path = Bundle.main.path(forResource: "mongod", ofType: "", inDirectory: "Vendor/mongodb") {
            self.task.launchPath = path
        }
        
        self.task.arguments = [
            "--dbpath", self.dataPath,
            "--nounixsocket",
            "--bind_ip", self.bindIp,
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
    
    func openMongo(_ sender: AnyObject) {
        if let path = Bundle.main.path(forResource: "mongo", ofType: "", inDirectory: "Vendor/mongodb") {
            var source: String
            
            if appExists("iTerm") {
                source = "tell application \"iTerm\" \n" +
                            "activate \n" +
                            "set newTerminal to (make new terminal) \n" +
                            "tell newTerminal \n" +
                                "launch session \"Default Session\" \n" +
                                "tell the last session \n" +
                                    "write text \"\(path)\" \n" +
                                "end tell \n" +
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
    
    func openDocumentationPage(_ send: AnyObject) {
        if let url: URL = URL(string: "https://github.com/gcollazo/mongodbapp") {
            NSWorkspace.shared().open(url)
        }
    }
    
    func openLogsDirectory(_ send: AnyObject) {
        NSWorkspace.shared().openFile(self.logPath)
    }
    
    func createDirectories() {
        if (!FileManager.default.fileExists(atPath: self.dataPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating dataPath")
            }
        }

        if (!FileManager.default.fileExists(atPath: self.logPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.logPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating logPath")
            }
        }

        print("Mongo server IP: \(self.bindIp)")
        print("Mongo data directory: \(self.dataPath)")
        print("Mongo logs directory: \(self.logPath)")
    }
    
    func checkForUpdates(_ sender: AnyObject?) {
        print("Checking for updates")
        self.updater.checkForUpdates(sender)
    }
    
    func setupSystemMenuItem() {
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        
        let icon = NSImage(named: "leaf")
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
        quitMenuItem.action = #selector(NSApplication.shared().terminate)
        menu.addItem(quitMenuItem)
    }
    
    func configurationFileExists() -> Bool {
        let configFile = (NSHomeDirectory() + "/.mongodb.conf")
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: configFile)
    }
    
    func configurationFileDefinitions() -> [String:String]{
        var options = [String:String]()
        let configFile = (NSHomeDirectory() + "/.mongodb.conf")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: configFile) {
            do {
                let fileContents = try String(contentsOfFile: configFile, encoding: String.Encoding.utf8)
                var optionPrefix = ""
                let fileLines = (fileContents.components(separatedBy: NSCharacterSet.newlines).filter{!$0.isEmpty && !$0.hasPrefix("#")})
                for line in fileLines {
                    let colonIndex = line.index(of: ":") ?? line.endIndex
                    var propertyKey = line.substring(to: colonIndex)
                    
                    let newOptionGroup = !line.hasPrefix(" ")
                    if newOptionGroup {
                        optionPrefix = propertyKey
                    }
                    else{
                        propertyKey = propertyKey.trimmingCharacters(in: NSCharacterSet.whitespaces)
                        let afterColonIndex = line.index(after: colonIndex)
                        let key = String("\(optionPrefix).\(propertyKey)")
                        let value = line.substring(from: afterColonIndex).trimmingCharacters(in: NSCharacterSet.whitespaces).replacingOccurrences(of: "\"", with: "")
                        options[key!] = value
                    }
                }
            }
            catch {print("Error reading .mongodb.conf file")}
        }
        return options
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

