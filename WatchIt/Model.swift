//
//  WatchesModel.swift
//  WatchIt
//
//  Created by Alec Thomas on 2/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation

public class Watch: EVObject {
    var name: String = ""
    var directory: String = ""
    var glob: String = ""
    var command: String = ""
    var pattern: String = ""

    var emptyPreset: Bool {
        return glob == "" && command == "" && pattern == ""
    }
}

public class Preset: EVObject {
    var name: String = ""
    var glob: String = ""
    var command: String = ""
    var pattern: String = ""
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


public class Model: EVObject {
    var watches: [Watch] = []
    var presets: [Preset] = []

    func presetForWatch(watch: Watch) -> Preset? {
        return presets.filter({p in p ~= watch}).first
    }

    static func deserialize() -> Model {
        log.info("deserializing model from \(modelPath)")
        do {
            let content = try String(contentsOfFile: modelPath)
            return Model(json: content)
        } catch {
            return Model()
        }
    }

    func serialize() throws {
        log.info("serializing model to \(modelPath)")
        let content = self.toJsonString()
        try content.writeToFile(modelPath, atomically: true, encoding: NSUTF8StringEncoding)
    }
}