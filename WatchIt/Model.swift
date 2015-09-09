//
//  WatchesModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import SwiftyJSON
import Bond

public protocol JSONSerializable {
    init(json: JSON) throws
    func toJSON() -> JSON
}

public class Watch: JSONSerializable, ObservableStructure {
    public var name = Observable<String>("")
    public var directory = Observable<String>("")
    public var glob = Observable<String>("")
    public var command = Observable<String>("")
    public var pattern = Observable<String>("")

    public var propertyChanged = Observable<String>("")

    public var emptyPreset: Bool {
        return glob == "" && command == "" && pattern == ""
    }

    public init() {
        name.map({_ in "name"}).bindTo(propertyChanged)
        directory.map({_ in "directory"}).bindTo(propertyChanged)
        glob.map({_ in "glob"}).bindTo(propertyChanged)
        command.map({_ in "command"}).bindTo(propertyChanged)
        pattern.map({_ in "pattern"}).bindTo(propertyChanged)
    }

    public convenience required init(json: JSON) throws {
        self.init()
        self.name.value = json["name"].stringValue
        self.directory.value = json["directory"].stringValue
        self.glob.value = json["glob"].stringValue
        self.command.value = json["command"].stringValue
        self.pattern.value = json["pattern"].stringValue
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
    public var name = Observable<String>("")
    public var glob = Observable<String>("")
    public var command = Observable<String>("")
    public var pattern = Observable<String>("")

    public var propertyChanged = Observable<String>("")

    public init() {
        name.map({_ in "name"}).bindTo(propertyChanged)
        glob.map({_ in "glob"}).bindTo(propertyChanged)
        command.map({_ in "command"}).bindTo(propertyChanged)
        pattern.map({_ in "pattern"}).bindTo(propertyChanged)
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
    public var watches = ObservableArray<Watch>([])
    public var presets = ObservableArray<Preset>([])

    public func presetForWatch(watch: Watch) -> Preset? {
        return presets.filter({p in p ~= watch}).first
    }

    public init() {}

    public required init(json: JSON) throws {
        watches.array.appendContentsOf(try json["watches"].arrayValue.map({v in try Watch(json: v)}))
        presets.array.appendContentsOf(try json["presets"].arrayValue.map({v in try Preset(json: v)}))
    }

    public func toJSON() -> JSON {
        return JSON([
            "watches": JSON(watches.array.map({v in v.toJSON()})),
            "presets": JSON(presets.array.map({v in v.toJSON()})),
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