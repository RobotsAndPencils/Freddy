//
//  JSON.swift
//  Freddy
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation

/// An enum to describe the structure of JSON.
public enum JSON {
    /// A case for denoting an array with an associated value of `[JSON]`
    case array([JSON])
    /// A case for denoting a dictionary with an associated value of `[Swift.String: JSON]`
    case dictionary([String: JSON])
    /// A case for denoting a decimal with an associated value of `Swift.Decimal`.
    case decimal(Decimal)
    /// A case for denoting a double with an associated value of `Swift.Double`.
    case double(Double)
    /// A case for denoting an integer with an associated value of `Swift.Int`.
    case int(Int)
    /// A case for denoting a string with an associated value of `Swift.String`.
    case string(String)
    /// A case for denoting a boolean with an associated value of `Swift.Bool`.
    case bool(Bool)
    /// A case for denoting null.
    case null
}

// MARK: - Errors

extension JSON {

    /// An enum to encapsulate errors that may arise in working with `JSON`.
    public enum Error: Swift.Error {
        /// The `index` is out of bounds for a JSON array
        case indexOutOfBounds(index: Int)
        
        /// The `key` was not found in the JSON dictionary
        case keyNotFound(key: String)
        
        /// The JSON is not subscriptable with `type`
        case unexpectedSubscript(type: JSONPathType.Type)
        
        /// Unexpected JSON `value` was found that is not convertible `to` type 
        case valueNotConvertible(value: JSON, to: Any.Type)
        
        /// The JSON is not serializable to a `String`.
        case stringSerializationError
    }

}

// MARK: - Test Equality

public extension Decimal {
    /// Taken verbatim from https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/NSDecimal.swift @ 46b4e84a263d4fb657d84dfa4ca5b8fb4ed1f75f
    /// Why? Decimal.doubleValue is internal. You can bridge to NSDecimalNumber and use its doubleValue property. What’s the implementation of NSDecimalNumber.doubleValue? `return decimal.doubleValue`. And NSDecimalNumber (or maybe just bridging to it) caused compiler crashes in release builds with (and sometimes without) whole-module optimization turned on.
    /// So, the real work is done in Decimal.doubleValue. If only we could do that work entirely with Decimal to get around the bridging crash...
    /// It turns out that the implementation of Decimal.doubleValue depends on public properties. It doesn't _look_ like it does, because they're all prefixed with an underscore, but the really-really-I-promise private properties have two underscores. Whatever, I'll take it.
    ///
    /// Related bug: "Decimal.doubleValue should be public" https://bugs.swift.org/browse/SR-4396
    var doubleValue: Double {
        var d = 0.0
        if _length == 0 && _isNegative == 1 {
            return Double.nan
        }

        d = d * 65536 + Double(_mantissa.7)
        d = d * 65536 + Double(_mantissa.6)
        d = d * 65536 + Double(_mantissa.5)
        d = d * 65536 + Double(_mantissa.4)
        d = d * 65536 + Double(_mantissa.3)
        d = d * 65536 + Double(_mantissa.2)
        d = d * 65536 + Double(_mantissa.1)
        d = d * 65536 + Double(_mantissa.0)

        if _exponent < 0 {
            for _ in _exponent..<0 {
                d /= 10.0
            }
        } else {
            for _ in 0..<_exponent {
                d *= 10.0
            }
        }
        return _isNegative != 0 ? -d : d
    }
    var intValue: Int {
        return Int(doubleValue)
    }
    var stringValue: String {
        return String(describing: doubleValue)
    }
}

/// Return `true` if `lhs` is equal to `rhs`.
public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.array(let arrL), .array(let arrR)):
        return arrL == arrR
    case (.dictionary(let dictL), .dictionary(let dictR)):
        return dictL == dictR
    case (.string(let strL), .string(let strR)):
        return strL == strR
    case (.decimal(let decL), .decimal(let decR)):
        return decL == decR
    case (.decimal(let decL), .double(let dubR)):
        return decL.doubleValue == dubR
    case (.double(let dubL), .decimal(let decR)):
        return dubL == decR.doubleValue
    case (.decimal(let decL), .int(let intR)):
        return decL.doubleValue == Double(intR)
    case (.int(let intL), .decimal(let decR)):
        return Double(intL) == decR.doubleValue
    case (.double(let dubL), .double(let dubR)):
        return dubL == dubR
    case (.double(let dubL), .int(let intR)):
        return dubL == Double(intR)
    case (.int(let intL), .int(let intR)):
        return intL == intR
    case (.int(let intL), .double(let dubR)):
        return Double(intL) == dubR
    case (.bool(let bL), .bool(let bR)):
        return bL == bR
    case (.null, .null):
        return true
    default:
        return false
    }
}

extension JSON: Equatable {}

// MARK: - Printing

extension JSON: CustomStringConvertible {

    /// A textual representation of `self`.
    public var description: Swift.String {
        switch self {
        case .array(let arr):       return String(describing: arr)
        case .dictionary(let dict): return String(describing: dict)
        case .string(let string):   return string
        case .decimal(let decimal): return String(describing: decimal)
        case .double(let double):   return String(describing: double)
        case .int(let int):         return String(describing: int)
        case .bool(let bool):       return String(describing: bool)
        case .null:                 return "null"
        }
    }

}
