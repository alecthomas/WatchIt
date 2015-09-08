//
//  Glob.swift
//  WatchIt
//
//  Created by Alec Thomas on 7/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation

public func glob(pattern: String, path: String) -> Bool {
    var out: String = ""
    var star = false
    for ch in pattern.characters {
        if ch == "*" {
            if star {
                out += ".*"
                star = false
            } else {
                star = true
            }
        } else {
            if star {
                out += "[^/]*"
                star = false
            }
            out.append(ch)
        }
    }
    if star {
        out += "[^/]*"
    }
    return out ~= path
}
