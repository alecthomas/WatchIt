//
//  WatchesModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift


public class Watch: ObservableStructure, CustomStringConvertible {
    public let id = Value<String>(NSUUID().UUIDString)
    public let name = Value<String>("")
    public let directory = Value<String>("")
    public let preset = Value<String>("")
    public let glob = Value<String>("")
    public let command = Value<String>("")
    public let pattern = Value<String>("")
    public let valid = Value<Bool>(false)
    public let running = Value<Bool>(false)
    public let output = Value<String>("")

    private let propertyChangedPublisher = PublishSubject<String>()
    public let propertyChanged: Observable<String>

    public var realPath: String {
        return directory.value.stringByExpandingTildeInPath.stringByResolvingSymlinksInPath
    }

    public var description: String {
        return "Watch(id: '\(id)', name: '\(name)', directory: '\(directory)', glob: '\(glob)', command: '\(command)', pattern: '\(pattern)')"
    }

    public init() {
        propertyChanged = propertyChangedPublisher
        id.map({_ in "id"}).subscribe(propertyChangedPublisher)
        name.map({_ in "name"}).subscribe(propertyChangedPublisher)
        directory.map({_ in "directory"}).subscribe(propertyChangedPublisher)
        preset.map({_ in "preset"}).subscribe(propertyChangedPublisher)
        glob.map({_ in "glob"}).subscribe(propertyChangedPublisher)
        command.map({_ in "command"}).subscribe(propertyChangedPublisher)
        pattern.map({_ in "pattern"}).subscribe(propertyChangedPublisher)
        id.subscribeNext{text in self.updateValid()}
        name.subscribeNext{text in self.updateValid()}
        directory.subscribeNext{text in self.updateValid()}
        preset.subscribeNext{text in self.updateValid()}
        glob.subscribeNext{text in self.updateValid()}
        command.subscribeNext{text in self.updateValid()}
        pattern.subscribeNext{text in self.updateValid()}
    }

    public convenience init(json: JSON, presets: [String:Preset]) throws {
        self.init()
        self.id.value = json["id"].string ?? NSUUID().UUIDString
        self.name.value = json["name"].stringValue
        self.directory.value = json["directory"].stringValue
        if let preset = json["preset"].string {
            self.preset.value = presets[preset]?.id.value ?? ""
        }
        self.glob.value = json["glob"].stringValue
        self.command.value = json["command"].stringValue
        self.pattern.value = json["pattern"].stringValue
    }

    public func validPath() -> Bool {
        var isDir: ObjCBool = false
        return NSFileManager.defaultManager().fileExistsAtPath(realPath, isDirectory: &isDir) && isDir
    }

    public func setPreset(preset: Preset?) {
        if let preset = preset {
            self.preset.value = preset.id.value
            self.glob.value = preset.glob.value
            self.pattern.value = preset.pattern.value
            self.command.value = preset.command.value
        } else {
            self.preset.value = ""
        }
    }

    public func toJSON() -> JSON {
        return JSON([
            "id": id.value,
            "name": name.value,
            "directory": directory.value,
            "preset": preset.value,
            "glob": glob.value,
            "command": command.value,
            "pattern": pattern.value
            ])
    }

    public func reset() {
        id.value = NSUUID().UUIDString
        name.value = ""
        directory.value = ""
        glob.value = ""
        command.value = ""
        pattern.value = ""
        preset.value = ""
    }
    
    private func updateValid() {
        valid.value = name.value != "" && validPath() && glob.value != "" && command.value != "" && Regex.valid(pattern.value)
    }
}

public class Preset: ObservableStructure {
    public let id = Value<String>("")
    public let name = Value<String>("")
    public let glob = Value<String>("")
    public let command = Value<String>("")
    public let pattern = Value<String>("")

    public let propertyChangedPublisher = PublishSubject<String>()
    public let propertyChanged: Observable<String>

    public init() {
        propertyChanged = propertyChangedPublisher
        id.map({_ in "id"}).subscribe(propertyChangedPublisher)
        name.map({_ in "name"}).subscribe(propertyChangedPublisher)
        glob.map({_ in "glob"}).subscribe(propertyChangedPublisher)
        command.map({_ in "command"}).subscribe(propertyChangedPublisher)
        pattern.map({_ in "pattern"}).subscribe(propertyChangedPublisher)
    }

    public convenience required init(json: JSON) throws {
        self.init()
        self.id.value = json["id"].stringValue
        self.name.value = json["name"].stringValue
        self.glob.value = json["glob"].stringValue
        self.command.value = json["command"].stringValue
        self.pattern.value = json["pattern"].stringValue
    }

    public func toJSON() -> JSON {
        return JSON([
            "id": id.value,
            "name": name.value,
            "glob": glob.value,
            "command": command.value,
            "pattern": pattern.value
            ])
    }
}

func != (a: Preset?, b: Preset?) -> Bool {
    return a?.id.value != b?.id.value
}

func ~= (preset: Preset, watch: Watch) -> Bool {
    return  preset.glob == watch.glob &&
        preset.command == watch.command &&
        preset.pattern == watch.pattern
}

func ~= (watch: Watch, preset: Preset) -> Bool {
    return preset ~= watch
}


let modelDirectory =  (NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] as NSString)
var modelPath = modelDirectory.stringByAppendingPathComponent("WatchIt.json")


public class Model {
    public var watches = ObservableCollection<Watch>()
    public var presets = ObservableCollection<Preset>()

    public init() {}

    public required init(json: JSON, defaults: JSON) throws {
        try mergeDefaults(defaults)
        var presetMap: [String:Preset] = [:]
        for preset in presets {
            presetMap[preset.id.value] = preset
        }
        watches.appendContentsOf(try json["watches"].array?.map({(v: JSON) in try Watch(json: v, presets: presetMap)}) ?? [])
    }

    public func mergeDefaults(json: JSON) throws {
        presets.removeAll()
        presets.appendContentsOf(try json["presets"].array?.map({v in try Preset(json: v)}) ?? [])
        // Update watches with preset values, if any.
        for watch in watches {
            if watch.preset.value != "" {
                if let preset = presetForId(watch.preset.value) {
                    watch.glob.value = preset.glob.value
                    watch.pattern.value = preset.pattern.value
                    watch.command.value = preset.command.value
                } else {
                    watch.preset.value = ""
                }
            }
        }
    }

    public func presetForId(id: String) -> Preset? {
        return presets.filter({p in p.id == id}).first
    }

    public func presetForWatch(watch: Watch) -> Preset? {
        return presets.filter({p in p ~= watch}).first
    }

    public func toJSON() -> JSON {
        return JSON([
            "watches": JSON(watches.map({v in v.toJSON()})),
            ])
    }

    private static func jsonForFile(path: String) -> JSON? {
        guard let data = NSData(contentsOfFile: path) else { return nil }
        return JSON(data: data)
    }

    private static func loadDefaults() -> JSON? {
        let bundle = NSBundle.mainBundle()
        guard let resource = bundle.pathForResource("WatchIt-defaults", ofType: "json") else { return nil }
        return jsonForFile(resource)
    }

    public static func deserialize() -> Model {
        log.info("deserializing model from \(modelPath)")
        do {
            let defaults = loadDefaults() ?? JSON([:])
            let config = jsonForFile(modelPath) ?? JSON([:])
            return try Model(json: config, defaults: defaults)
        } catch let err {
            log.error("error loading config: \(err)")
            return Model()
        }
    }

    public func serialize() throws {
        log.info("serializing model to \(modelPath)")
        let data = try self.toJSON().rawData()
        data.writeToFile(modelPath, atomically: true)
    }
}