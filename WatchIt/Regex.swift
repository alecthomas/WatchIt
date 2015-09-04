//
//  Regex.swift
//  WatchIt
//
//  Created by Alec Thomas on 4/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import pcre

enum RegexError: ErrorType {
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

    static func fromError(value: Int32) -> RegexError {
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
            fatalError("unknown PCRE error \(value)")
        }
    }
}

struct RegexOptions: OptionSetType {
    let rawValue: Int32
    init(rawValue: Int32) { self.rawValue = rawValue }

    static var None = RegexOptions(rawValue: 0)

    static var ANCHORED = RegexOptions(rawValue: pcre.PCRE_ANCHORED)
    static var AUTO_CALLOUT = RegexOptions(rawValue: pcre.PCRE_AUTO_CALLOUT)
    static var BSR_ANYCRLF = RegexOptions(rawValue: pcre.PCRE_BSR_ANYCRLF)
    static var BSR_UNICODE = RegexOptions(rawValue: pcre.PCRE_BSR_UNICODE)
    static var CASELESS = RegexOptions(rawValue: pcre.PCRE_CASELESS)
    static var DOLLAR_ENDONLY = RegexOptions(rawValue: pcre.PCRE_DOLLAR_ENDONLY)
    static var DOTALL = RegexOptions(rawValue: pcre.PCRE_DOTALL)
    static var DUPNAMES = RegexOptions(rawValue: pcre.PCRE_DUPNAMES)
    static var EXTENDED = RegexOptions(rawValue: pcre.PCRE_EXTENDED)
    static var EXTRA = RegexOptions(rawValue: pcre.PCRE_EXTRA)
    static var FIRSTLINE = RegexOptions(rawValue: pcre.PCRE_FIRSTLINE)
    static var JAVASCRIPT_COMPAT = RegexOptions(rawValue: pcre.PCRE_JAVASCRIPT_COMPAT)
    static var MULTILINE = RegexOptions(rawValue: pcre.PCRE_MULTILINE)
    static var NEVER_UTF = RegexOptions(rawValue: pcre.PCRE_NEVER_UTF)
    static var NEWLINE_ANY = RegexOptions(rawValue: pcre.PCRE_NEWLINE_ANY)
    static var NEWLINE_ANYCRLF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_ANYCRLF)
    static var NEWLINE_CR = RegexOptions(rawValue: pcre.PCRE_NEWLINE_CR)
    static var NEWLINE_CRLF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_CRLF)
    static var NEWLINE_LF = RegexOptions(rawValue: pcre.PCRE_NEWLINE_LF)
    static var NO_AUTO_CAPTURE = RegexOptions(rawValue: pcre.PCRE_NO_AUTO_CAPTURE)
    static var NO_AUTO_POSSESS = RegexOptions(rawValue: pcre.PCRE_NO_AUTO_POSSESS)
    static var NO_START_OPTIMIZE = RegexOptions(rawValue: pcre.PCRE_NO_START_OPTIMIZE)
    static var NO_UTF16_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF16_CHECK)
    static var NO_UTF32_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF32_CHECK)
    static var NO_UTF8_CHECK = RegexOptions(rawValue: pcre.PCRE_NO_UTF8_CHECK)
    static var UCP = RegexOptions(rawValue: pcre.PCRE_UCP)
    static var UNGREEDY = RegexOptions(rawValue: pcre.PCRE_UNGREEDY)
    static var UTF16 = RegexOptions(rawValue: pcre.PCRE_UTF16)
    static var UTF32 = RegexOptions(rawValue: pcre.PCRE_UTF32)
    static var UTF8 = RegexOptions(rawValue: pcre.PCRE_UTF8)

    // Specific to pcre_exec()
    static var NOTBOL = RegexOptions(rawValue: pcre.PCRE_NOTBOL)
    static var NOTEOL = RegexOptions(rawValue: pcre.PCRE_NOTEOL)
    static var NOTEMPTY = RegexOptions(rawValue: pcre.PCRE_NOTEMPTY)
    static var NOTEMPTY_ATSTART = RegexOptions(rawValue: pcre.PCRE_NOTEMPTY_ATSTART)
    static var PARTIAL = RegexOptions(rawValue: pcre.PCRE_PARTIAL)
    static var PARTIAL_SOFT = RegexOptions(rawValue: pcre.PCRE_PARTIAL_SOFT)
    static var PARTIAL_HARD = RegexOptions(rawValue: pcre.PCRE_PARTIAL_HARD)
}

func | (a: RegexOptions, b: RegexOptions) -> RegexOptions {
    return a.union(b)
}

class RegexMatch {
    let re: Regex
    let subject: [CChar]
    let ovector: UnsafeMutablePointer<Int32>
    let stringcount: Int32

    init(re: Regex, subject: [CChar], ovector: UnsafeMutablePointer<Int32>, stringcount: Int32) {
        self.re = re
        self.subject = subject
        self.ovector = ovector
        self.stringcount = stringcount
    }

    // Retrieve captured substring.
    subscript(index: Int) -> String? {
        let out = UnsafeMutablePointer<Int8>.alloc(256)
        let length = pcre_copy_substring(subject, ovector, stringcount, Int32(index), out, 256)
        if length < 0 {
            out.destroy()
            return nil
        }
        let result = String.fromCString(UnsafePointer<CChar>(out))
        out.destroy()
        return result
    }

    // Retrieve named captured substring.
    subscript(name: String) -> String? {
        let out = UnsafeMutablePointer<Int8>.alloc(256)
        let length = pcre_copy_named_substring(re.re, subject, ovector, stringcount, name, out, 256)
        if length < 0 {
            out.destroy()
            return nil
        }
        let result = String.fromCString(UnsafePointer<CChar>(out))
        out.destroy()
        return result
    }

    deinit {
        ovector.destroy()
    }
}

class Regex {
    let re: COpaquePointer

    static func valid(pattern: String, options: RegexOptions = RegexOptions.None) -> Bool {
        do {
            let _ = try Regex(pattern: pattern, options: options)
            return true
        } catch {
            return false
        }
    }

    init(pattern: String, options: RegexOptions = RegexOptions.None) throws {
        let error = UnsafeMutablePointer<UnsafePointer<Int8>>.alloc(1)
        let offset = UnsafeMutablePointer<Int32>.alloc(1)
        let utf8Pattern = pattern.cStringUsingEncoding(NSUTF8StringEncoding)!
        re = pcre_compile(utf8Pattern, options.rawValue, error, offset, nil)
        if re == nil {
            let message = String.fromCString(error[0])!
            error.destroy()
            offset.destroy()
            throw RegexError.Message(message)
        }
        error.destroy()
        offset.destroy()
    }

    func matchNamedGroups(text: String, options: RegexOptions = RegexOptions.None) throws -> RegexMatch {
        let ovector = UnsafeMutablePointer<Int32>.alloc(3 * 32)
        let utf8Text = text.cStringUsingEncoding(NSUTF8StringEncoding)!
        let matches = pcre_exec(re, nil, utf8Text, Int32(utf8Text.count), 0, options.rawValue, ovector, 3 * 32)
        if matches < 0 {
            ovector.destroy()
            throw RegexError.fromError(matches)
        }
        return RegexMatch(re: self, subject: utf8Text, ovector: ovector, stringcount: matches)
    }

    deinit {
        pcre_free_wrapper(UnsafeMutablePointer<Void>(re))
    }
}