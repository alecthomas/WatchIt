//
//  WatchesModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import SwiftyJSON

public protocol JSONSerializable {
    init(json: JSON) throws
    func toJSON() -> JSON
}

public class Watch: JSONSerializable {
    public var name: String = ""
    public var directory: String = ""
    public var glob: String = ""
    public var command: String = ""
    public var pattern: String = ""

    public var emptyPreset: Bool {
        return glob == "" && command == "" && pattern == ""
    }

    public init() {}

    public required init(json: JSON) throws {
        self.name = json["name"].stringValue
        self.directory = json["directory"].stringValue
        self.glob = json["glob"].stringValue
        self.command = json["command"].stringValue
        self.pattern = json["pattern"].stringValue
    }

    public func toJSON() -> JSON {
        return JSON([
            "name": name,
            "directory": directory,
            "glob": glob,
            "command": command,
            "pattern": pattern
            ])
    }
}

public class Preset: JSONSerializable {
    public var name: String = ""
    public var glob: String = ""
    public var command: String = ""
    public var pattern: String = ""

    public init() {}

    public required init(json: JSON) throws {
        self.name = json["name"].stringValue
        self.glob = json["glob"].stringValue
        self.command = json["command"].stringValue
        self.pattern = json["pattern"].stringValue
    }

    public func toJSON() -> JSON {
        return JSON([
            "name": name,
            "glob": glob,
            "command": command,
            "pattern": pattern
            ])
    }
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
    var watches: ObservableCollection<Watch> = []
    var presets: ObservableCollection<Preset> = []

    func presetForWatch(watch: Watch) -> Preset? {
        return presets.filter({p in p ~= watch}).first
    }

    public init() {
    }

    public required init(json: JSON) throws {
        watches.appendContentsOf(try json["watches"].arrayValue.map({v in try Watch(json: v)}))
        presets.appendContentsOf(try json["presets"].arrayValue.map({v in try Preset(json: v)}))
    }

    public func toJSON() -> JSON {
        return JSON([
            "watches": JSON(watches.map({v in v.toJSON()})),
            "presets": JSON(presets.map({v in v.toJSON()})),
            ])
    }

    static func deserialize() -> Model {
        log.info("deserializing model from \(modelPath)")
        do {
            guard let data = NSData(contentsOfFile: modelPath) else { return  Model() }
            return try Model(json: JSON(data: data))
        } catch {
            return Model()
        }
    }

    func serialize() throws {
        log.info("serializing model to \(modelPath)")
        let data = try self.toJSON().rawData()
        data.writeToFile(modelPath, atomically: true)
    }
}