//
//  Regex.swift
//  WatchIt
//
//  Created by Alec Thomas on 4/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import pcre

public enum RegexError: ErrorType {
    case Message(String)

    case NOMATCH
    case NULL
    case BADOPTION
    case BADMAGIC
    case UNKNOWN_OPCODE
    case UNKNOWN_NODE
    case NOMEMORY
    case NOSUBSTRING
    case MATCHLIMIT
    case CALLOUT
    case BADUTF8
    case BADUTF16
    case BADUTF32
    case BADUTF8_OFFSET
    case BADUTF16_OFFSET
    case PARTIAL
    case BADPARTIAL
    case INTERNAL
    case BADCOUNT
    case DFA_UITEM
    case DFA_UCOND
    case DFA_UMLIMIT
    case DFA_WSSIZE
    case DFA_RECURSE
    case RECURSIONLIMIT
    case NULLWSLIMIT
    case BADNEWLINE
    case BADOFFSET
    case SHORTUTF8
    case SHORTUTF16
    case RECURSELOOP
    case JIT_STACKLIMIT
    case BADMODE
    case BADENDIANNESS
    case DFA_BADRESTART
    case JIT_BADOPTION
    case BADLENGTH
    case UNSET

    public static func fromError(value: Int32) -> RegexError {
        switch value {
        case PCRE_ERROR_NOMATCH: return .NOMATCH
        case PCRE_ERROR_NULL: return .NULL
        case PCRE_ERROR_BADOPTION: return .BADOPTION
        case PCRE_ERROR_BADMAGIC: return .BADMAGIC
        case PCRE_ERROR_UNKNOWN_OPCODE: return .UNKNOWN_OPCODE
        case PCRE_ERROR_UNKNOWN_NODE: return .UNKNOWN_NODE
        case PCRE_ERROR_NOMEMORY: return .NOMEMORY
        case PCRE_ERROR_NOSUBSTRING: return .NOSUBSTRING
        case PCRE_ERROR_MATCHLIMIT: return .MATCHLIMIT
        case PCRE_ERROR_CALLOUT: return .CALLOUT
        case PCRE_ERROR_BADUTF8: return .BADUTF8
        case PCRE_ERROR_BADUTF16: return .BADUTF16
        case PCRE_ERROR_BADUTF32: return .BADUTF32
        case PCRE_ERROR_BADUTF8_OFFSET: return .BADUTF8_OFFSET
        case PCRE_ERROR_BADUTF16_OFFSET: return .BADUTF16_OFFSET
        case PCRE_ERROR_PARTIAL: return .PARTIAL
        case PCRE_ERROR_BADPARTIAL: return .BADPARTIAL
        case PCRE_ERROR_INTERNAL: return .INTERNAL
        case PCRE_ERROR_BADCOUNT: return .BADCOUNT
        case PCRE_ERROR_DFA_UITEM: return .DFA_UITEM
        case PCRE_ERROR_DFA_UCOND: return .DFA_UCOND
        case PCRE_ERROR_DFA_UMLIMIT: return .DFA_UMLIMIT
        case PCRE_ERROR_DFA_WSSIZE: return .DFA_WSSIZE
        case PCRE_ERROR_DFA_RECURSE: return .DFA_RECURSE
        case PCRE_ERROR_RECURSIONLIMIT: return .RECURSIONLIMIT
        case PCRE_ERROR_NULLWSLIMIT: return .NULLWSLIMIT
        case PCRE_ERROR_BADNEWLINE: return .BADNEWLINE
        case PCRE_ERROR_BADOFFSET: return .BADOFFSET
        case PCRE_ERROR_SHORTUTF8: return .SHORTUTF8
        case PCRE_ERROR_SHORTUTF16: return .SHORTUTF16
        case PCRE_ERROR_RECURSELOOP: return .RECURSELOOP
        case PCRE_ERROR_JIT_STACKLIMIT: return .JIT_STACKLIMIT
        case PCRE_ERROR_BADMODE: return .BADMODE
        case PCRE_ERROR_BADENDIANNESS: return .BADENDIANNESS
        case PCRE_ERROR_DFA_BADRESTART: return .DFA_BADRESTART
        case PCRE_ERROR_JIT_BADOPTION: return .JIT_BADOPTION
        case PCRE_ERROR_BADLENGTH: return .BADLENGTH
        case PCRE_ERROR_UNSET: return .UNSET
        default:
            return .Message("unknown PCRE error \(value)")
        }
    }
}

public struct RegexOptions: OptionSetType {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let None = RegexOptions(rawValue: 0)

    public static let ANCHORED = RegexOptions(rawValue: pcre.PCRE_ANCHORED)
    public static let AUTO_CALLOUT = RegexOptions(rawValue: pcre.PCRE_AUTO_CALLOUT)
    public static let BSR_ANYCRLF = RegexOptions(rawValue: pcre.PCRE_BSR_ANYCRLF)
    public static let BSR_UNICODE = RegexOptions(rawValue: pcre.PCRE_BSR_UNICODE)
    public static let CASELESS = RegexOptions(rawValue: pcre.PCRE_CASELESS)
    public static let DOLLAR_ENDONLY = RegexOptions(rawValue: pcre.PCRE_DOLLAR_ENDONLY)
    public static let DOTALL = RegexOptions(rawValue: pcre.PCRE_DOTALL)
    public static let DUPNAMES = RegexOptions(rawValue: pcre.PCRE_DUPNAMES)
    public static let EXTENDED = RegexOptions(rawValue: pcre.PCRE_EXTENDED)
    public static let EXTRA = RegexOptions(rawValue: pcre.PCRE_EXTRA)
    public static let FIRSTLINE = RegexOptions(rawValue: pcre.PCRE_FIRSTLINE)
    public static let JAVASCRIPT_COMPAT = RegexOptions(rawValue: pcre.PCRE_JAVASCRIPT_COMPAT)
    public static let MULTILINE = RegexOptions(rawValue: pcre.PCRE_MULTILINE)
    public static let NEVER_UTF = RegexOptions(rawValue: pcre.PCRE_NEVER_UTF)
    public static let NEWLINE_ANY = RegexOptions(rawValue: pcre.PCRE_NEWLINE_ANY)
    public static let NEWLINE_ANYCRLF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_ANYCRLF)
    public static let NEWLINE_CR = RegexOptions(rawValue: pcre.PCRE_NEWLINE_CR)
    public static let NEWLINE_CRLF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_CRLF)
    public static let NEWLINE_LF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_LF)
    public static let NO_AUTO_CAPTURE = RegexOptions(rawValue: pcre.PCRE_NO_AUTO_CAPTURE)
    public static let NO_AUTO_POSSESS = RegexOptions(rawValue: pcre.PCRE_NO_AUTO_POSSESS)
    public static let NO_START_OPTIMIZE = RegexOptions(rawValue: pcre.PCRE_NO_START_OPTIMIZE)
    public static let NO_UTF16_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF16_CHECK)
    public static let NO_UTF32_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF32_CHECK)
    public static let NO_UTF8_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF8_CHECK)
    public static let UCP = RegexOptions(rawValue: pcre.PCRE_UCP)
    public static let UNGREEDY = RegexOptions(rawValue: pcre.PCRE_UNGREEDY)
    public static let UTF16 = RegexOptions(rawValue: pcre.PCRE_UTF16)
    public static let UTF32 = RegexOptions(rawValue: pcre.PCRE_UTF32)
    public static let UTF8 = RegexOptions(rawValue: pcre.PCRE_UTF8)

    // Specific to pcre_exec()
    public static let NOTBOL = RegexOptions(rawValue: pcre.PCRE_NOTBOL)
    public static let NOTEOL = RegexOptions(rawValue: pcre.PCRE_NOTEOL)
    public static let NOTEMPTY = RegexOptions(rawValue: pcre.PCRE_NOTEMPTY)
    public static let NOTEMPTY_ATSTART = RegexOptions(rawValue: pcre.PCRE_NOTEMPTY_ATSTART)
    public static let PARTIAL = RegexOptions(rawValue: pcre.PCRE_PARTIAL)
    public static let PARTIAL_SOFT = RegexOptions(rawValue: pcre.PCRE_PARTIAL_SOFT)
    public static let PARTIAL_HARD = RegexOptions(rawValue: pcre.PCRE_PARTIAL_HARD)
}

public func | (a: RegexOptions, b: RegexOptions) -> RegexOptions {
    return a.union(b)
}

public func & (a: RegexOptions, b: RegexOptions) -> RegexOptions {
    return a.intersect(b)
}

// Replace match from text with text.
private func replaceMatch(match: RegexMatch, replaceWith: String) -> (Range<String.Index>, String) {
    var replacement = ""
    var escaping = false
    for ch in replaceWith.characters {
        if ch == "\\" {
            escaping = true
        } else if escaping {
            // Substitute capture group.
            if let i = Int(String(ch)), let g = match[i] {
                replacement.appendContentsOf(g)
            } else {
                // Something else was escaped, just put it back.
                replacement.appendContentsOf("\\\(ch)")
            }
            escaping = false
        } else {
            replacement.append(ch)
        }
    }
    return (match.ranges[0]!, replacement)
}


public class RegexMatch: /*Indexable,*/ SequenceType, CustomStringConvertible {
    public typealias Index = String.Index

    private let re: Regex

    public let string: String

    // The set of matching groups.
    public var ranges: [Range<String.Index>?]

    private init(re: Regex, string: String, ovector: UnsafeMutablePointer<Int32>, matches: Int32) {
        self.re = re
        self.string = string
        ranges = []
        for var i: Int = 0; i < Int(matches); i++ {
            let start = Int(ovector[i*2])
            let end = Int(ovector[i*2+1])
            if start < 0 || end < 0 {
                ranges.append(nil)
            } else {
                ranges.append(Range(start: string.startIndex.advancedBy(start), end: string.startIndex.advancedBy(end)))
            }
        }
    }

    // Subscript a range (typically returned by .ranges).
    public subscript(r: Range<String.Index>?) -> String? {
        if r == nil {
            return nil
        }
        return self.string[r!]
    }

    // Retrieve captured substring.
    public subscript(i: Int) -> String? {
        if i < 0 || i >= ranges.count {
            return nil
        }
        return self[ranges[i]]
    }

    // Retrieve named captured substring.
    public subscript(name: String) -> String? {
        let index = pcre_get_stringnumber(re.re, name)
        return self[Int(index)]
    }

    public func replace(with: String) -> String {
        let (range, replacement) = replaceMatch(self, replaceWith: with)
        var out = string
        out.replaceRange(range, with: replacement)
        return out
    }

    public var description: String {
        return string
    }

    // Number of matches.
    public var count: Int {
        return ranges.count
    }

    // Iterate over match groups.
    public func generate() -> AnyGenerator<String?> {
        var index = 0
        return anyGenerator {
            if index >= self.count {
                return nil
            }
            return self[index++]
        }
    }
}

// A PCRE regular expression.
public class Regex {
    private let re: COpaquePointer

    // Check if the given string is a valid PCRE regular expression.
    public static func valid(pattern: String, options: RegexOptions = RegexOptions.None) -> Bool {
        do {
            let _ = try Regex(pattern: pattern, options: options)
            return true
        } catch {
            return false
        }
    }

    public init(pattern: String, options: RegexOptions = RegexOptions.None) throws {
        let error = UnsafeMutablePointer<UnsafePointer<Int8>>.alloc(1)
        let offset = UnsafeMutablePointer<Int32>.alloc(1)
        defer { error.destroy(); offset.destroy() }
        let utf8Pattern = pattern.cStringUsingEncoding(NSUTF8StringEncoding)!
        re = pcre_compile(utf8Pattern, options.rawValue, error, offset, nil)
        if re == nil {
            guard let message = String.fromCString(error[0]) else { throw RegexError.BADUTF8 }
            throw RegexError.Message(message)
        }
    }

    // Matches text completely against the regular expression.
    public func match(text: String, options: RegexOptions = RegexOptions.None) throws -> RegexMatch? {
        if let m = try search(text, options: options), let g = m.ranges[0]
                where g.startIndex == text.startIndex && g.endIndex == text.endIndex {
            return m
        }
        return nil
    }

    // Find the first occurrence of the regular expression in the text.
    public func search(text: String, options: RegexOptions = RegexOptions.None) throws -> RegexMatch? {
        let matches = try findAll(text, count: 1, options: options)
        if matches.count > 0 {
            return matches[0]
        }
        return nil
    }

    // Find all matches in text.
    public func findAll(text: String, count: Int = Int.max, options: RegexOptions = RegexOptions.None) throws -> [RegexMatch] {
        guard let utf8Text = text.cStringUsingEncoding(NSUTF8StringEncoding) else { throw RegexError.BADUTF8 }
        let utf8Length = Int32(utf8Text.count) - 1 // Ignore \0
        var out: [RegexMatch] = []
        var offset: Int32 = 0
        let ovector = UnsafeMutablePointer<Int32>.alloc(3 * 32)
        var n = 0
        defer { ovector.destroy() }
        while true {
            let matches = pcre_exec(re, nil, utf8Text, utf8Length, offset, options.rawValue, ovector, 3 * 32)
            if matches < 0 {
                if matches == PCRE_ERROR_NOMATCH {
                    break
                }
                throw RegexError.fromError(matches)
            }
            out.append(RegexMatch(re: self, string: text, ovector: ovector, matches: matches))
            offset = ovector[Int(matches-1)*2+1]
            if ++n >= count {
                break
            }
        }
        return out
    }

    // Match "text" against this regular expression, replacing \\<digit> references
    // in "replace" with the corresponding capture groups from text.
    public func replace(text: String, with: String, count: Int = Int.max, options: RegexOptions = RegexOptions.None) throws -> String {
        var n = 0
        var start = text.startIndex
        var parts: [String] = []
        for match in try findAll(text, options: options) {
            let (range, replacement) = replaceMatch(match, replaceWith: with)
            parts.append(text[Range<String.Index>(start: start, end: range.startIndex)])
            parts.append(replacement)
            start = range.endIndex
            if ++n >= count {
                break
            }
        }
        parts.append(text[Range<String.Index>(start: start, end: text.endIndex)])
        return parts.joinWithSeparator("")
    }

    deinit {
        pcre_free_wrapper(UnsafeMutablePointer<Void>(re))
    }
}

// Match re against text.
public func ~= (re: Regex, text: String) -> Bool {
    do {
        return try re.match(text) != nil
    } catch {
        return false
    }
}

// Match (uncompiled) re against text.
public func ~= (re: String, text: String) -> Bool {
    do {
        return try Regex(pattern: re).match(text) != nil
    } catch {
        return false
    }
}