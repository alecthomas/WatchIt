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

public protocol JSONSerializable {
    init(json: JSON) throws
    func toJSON() -> JSON
}

public class Watch: JSONSerializable, ObservableStructure {
    public var name = Value<String>("")
    public var directory = Value<String>("")
    public var glob = Value<String>("")
    public var command = Value<String>("")
    public var pattern = Value<String>("")

    private let propertyChangedPublisher = PublishSubject<String>()
    public let propertyChanged: Observable<String>

    // Are the preset values in this watch empty?
    public var emptyPreset: Bool {
        return glob == "" && command == "" && pattern == ""
    }

    public var realPath: String {
        return directory.value.stringByExpandingTildeInPath.stringByResolvingSymlinksInPath
    }

    public init() {
        propertyChanged = propertyChangedPublisher
        name.map({_ in "name"}).subscribe(propertyChangedPublisher)
        directory.map({_ in "directory"}).subscribe(propertyChangedPublisher)
        glob.map({_ in "glob"}).subscribe(propertyChangedPublisher)
        command.map({_ in "command"}).subscribe(propertyChangedPublisher)
        pattern.map({_ in "pattern"}).subscribe(propertyChangedPublisher)
    }

    public convenience required init(json: JSON) throws {
        self.init()
        self.name.value = json["name"].stringValue
        self.directory.value = json["directory"].stringValue
        self.glob.value = json["glob"].stringValue
        self.command.value = json["command"].stringValue
        self.pattern.value = json["pattern"].stringValue
    }

    public func validPath() -> Bool {
        var isDir: ObjCBool = false
        return NSFileManager.defaultManager().fileExistsAtPath(realPath, isDirectory: &isDir) && isDir
    }

    public func valid() -> Bool {
        return validPath() && glob.value != "" && command.value != "" && Regex.valid(pattern.value)
    }

    public func toJSON() -> JSON {
        return JSON([
            "name": name.value,
            "directory": directory.value,
            "glob": glob.value,
            "command": command.value,
            "pattern": pattern.value
            ])
    }

    public func reset() {
        name.value = ""
        directory.value = ""
        glob.value = ""
        command.value = ""
        pattern.value = ""
    }
}

public class Preset: JSONSerializable, ObservableStructure {
    public var name = Value<String>("")
    public var glob = Value<String>("")
    public var command = Value<String>("")
    public var pattern = Value<String>("")

    public let propertyChangedPublisher = PublishSubject<String>()
    public let propertyChanged: Observable<String>

    public init() {
        propertyChanged = propertyChangedPublisher
        name.map({_ in "name"}).subscribe(propertyChangedPublisher)
        glob.map({_ in "glob"}).subscribe(propertyChangedPublisher)
        command.map({_ in "command"}).subscribe(propertyChangedPublisher)
        pattern.map({_ in "pattern"}).subscribe(propertyChangedPublisher)
    }

    public convenience required init(json: JSON) throws {
        self.init()
        self.name.value = json["name"].stringValue
        self.glob.value = json["glob"].stringValue
        self.command.value = json["command"].stringValue
        self.pattern.value = json["pattern"].stringValue
    }

    public func toJSON() -> JSON {
        return JSON([
            "name": name.value,
            "glob": glob.value,
            "command": command.value,
            "pattern": pattern.value
            ])
    }
}

func != (a: Preset?, b: Preset?) -> Bool {
    return a?.name.value != b?.name.value
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


public class Model: JSONSerializable {
    public var watches = ObservableCollection<Watch>()
    public var presets = ObservableCollection<Preset>()

    public init() {}

    public required init(json: JSON) throws {
        watches.appendContentsOf(try json["watches"].arrayValue.map({v in try Watch(json: v)}))
        presets.appendContentsOf(try json["presets"].arrayValue.map({v in try Preset(json: v)}))
    }

    public func presetForWatch(watch: Watch) -> Preset? {
        return presets.filter({p in p ~= watch}).first
    }

    public func toJSON() -> JSON {
        return JSON([
            "watches": JSON(watches.map({v in v.toJSON()})),
            "presets": JSON(presets.map({v in v.toJSON()})),
            ])
    }

    public static func deserialize() -> Model {
        log.info("deserializing model from \(modelPath)")
        do {
            guard let data = NSData(contentsOfFile: modelPath) else { return  Model() }
            return try Model(json: JSON(data: data))
        } catch {
            return Model()
        }
    }

    public func serialize() throws {
        log.info("serializing model to \(modelPath)")
        let data = try self.toJSON().rawData()
        data.writeToFile(modelPath, atomically: true)
    }
}