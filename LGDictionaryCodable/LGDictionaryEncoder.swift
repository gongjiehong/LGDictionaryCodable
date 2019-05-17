//
//  LGDictionaryEncoder.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/25.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

open class LGDictionaryEncoder {
    // MARK: Options
    
    /// The formatting of the output Dictionary.
    public struct OutputFormatting : OptionSet {
        /// The format's default value.
        public let rawValue: UInt
        
        /// Creates an OutputFormatting value with the given raw value.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        /// Produce human-readable Dictionary with indented output.
        public static let prettyPrinted = OutputFormatting(rawValue: 1 << 0)
        
        /// Produce Dictionary with dictionary keys sorted in lexicographic order.
        @available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
        public static let sortedKeys    = OutputFormatting(rawValue: 1 << 1)
    }
    
    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy {
        /// Defer to `Date` for choosing an encoding. This is the default strategy.
        case deferredToDate
        
        /// Encode the `Date` as a UNIX timestamp (as a number).
        case secondsSince1970
        
        /// Encode the `Date` as UNIX millisecond timestamp (as a number).
        case millisecondsSince1970
        
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataEncodingStrategy {
        /// Raw data, no processing. This is the default strategy.
        case raw
        
        /// Encoded the `Data` as a Base64-encoded string.
        case base64
        
        /// Encoded the child Encodable object or array to data.
        case codableToData
    }
    
    /// The strategy to use for non-Dictionary-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatEncodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Encode the values using the given representation strings.
        case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to dictionary payload.
        ///
        /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase
        
        /// Provide a custom conversion to the key in the encoded dictionary from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload).
        /// The returned key is used in place of the last component in the coding path before encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
        
        fileprivate static func _convertToSnakeCase(_ stringKey: String) -> String {
            guard !stringKey.isEmpty else { return stringKey }
            
            var words : [Range<String.Index>] = []
            // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
            //
            // myProperty -> my_property
            // myURLProperty -> my_url_property
            //
            // We assume, per Swift naming conventions, that the first character of the key is lowercase.
            var wordStart = stringKey.startIndex
            var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex
            
            // Find next uppercase character
            while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters,
                                                                  options: [], range: searchRange)
            {
                let untilUpperCase = wordStart..<upperCaseRange.lowerBound
                words.append(untilUpperCase)
                
                // Find next lowercase character
                searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
                guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters,
                                                                      options: [],
                                                                      range: searchRange) else
                {
                    // There are no more lower case letters. Just end here.
                    wordStart = searchRange.lowerBound
                    break
                }
                
                // Is the next lowercase letter more than 1 after the uppercase?
                // If so, we encountered a group of uppercase letters that we should treat as its own word
                let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
                if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                    // The next character after capital is a lower case character and therefore not a word boundary.
                    // Continue searching for the next upper case for the boundary.
                    wordStart = upperCaseRange.lowerBound
                } else {
                    // There was a range of >1 capital letters.
                    // Turn those into a word, stopping at the capital before the lower case character.
                    let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                    words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                    
                    // Next word starts at the capital before the lowercase we just found
                    wordStart = beforeLowerIndex
                }
                searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
            }
            words.append(wordStart..<searchRange.upperBound)
            let result = words.map({ (range) in
                return stringKey[range].lowercased()
            }).joined(separator: "_")
            return result
        }
    }
    
    /// The output format to produce. Defaults to `[]`.
    open var outputFormatting: OutputFormatting = []
    
    /// The strategy to use in encoding dates. Defaults to `.deferredToDate`.
    open var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
    
    /// The strategy to use in encoding binary data. Defaults to `.base64`.
    open var dataEncodingStrategy: DataEncodingStrategy = .base64
    
    /// The strategy to use in encoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw
    
    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    
    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: KeyEncodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }
    
    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        dataEncodingStrategy: dataEncodingStrategy,
                        nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                        keyEncodingStrategy: keyEncodingStrategy,
                        userInfo: userInfo)
    }
    
    // MARK: - Constructing a Dictionary Encoder
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Encoding Values
    
    /// Encodes the given top-level value and returns its Dictionary representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded Dictionary.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> Any {
        let encoder = __LGDictionaryEncoder(options: self.options)
        
        let result = try encoder.encodeToAny(value)
        
        if let dictionary = result as? [String: Any] {
            return dictionary
        } else if let array = result as? [Any] {
            return array
        } else {
            let debugDescription = "Top-level \(T.self) did not encode any values."
            let context = EncodingError.Context(codingPath: [], debugDescription: debugDescription)
            throw EncodingError.invalidValue(value, context)
        }
    }
}

fileprivate class __LGDictionaryEncoder: Swift.Encoder, _DictionaryEncodingContainer {
    let codingPath: [CodingKey]
    
    let options: LGDictionaryEncoder._Options
    
    var userInfo: [CodingUserInfoKey: Any] {
        return options.userInfo
    }
    
    init(options: LGDictionaryEncoder._Options, codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.options = options
    }
    
    private var _container: _DictionaryEncodingContainer?
    private(set) var container: _DictionaryEncodingContainer? {
        set {
            if _container == nil {
                _container = newValue
            }
        } get {
            return _container
        }
    }
    
    func toAny() throws -> Any {
        guard let container = self.container else {
            let debugDescription = "Top-level \(Any.self) did not encode any values."
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw EncodingError.invalidValue("Empty Value", context)
        }
        
        return try container.toAny()
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let keyed = _EncodingKeyedContainer<Key>(codingPath: self.codingPath,
                                                 options: self.options,
                                                 encoder: self)
        container = keyed
        return KeyedEncodingContainer(keyed)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let unkeyed = _EncodingUnkeyedContainer(codingPath: self.codingPath,
                                                options: self.options,
                                                encoder: self)
        container = unkeyed
        return unkeyed
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        let single = _EncodingSingleContainer(codingPath: self.codingPath,
                                              options: self.options,
                                              encoder: self)
        container = single
        return single
    }
    
    func encodeToAny<T>(_ value: T) throws -> Any where T: Encodable {
        try value.encode(to: self)
        return try toAny()
    }
}

fileprivate protocol _DictionaryEncodingContainer {
    func toAny() throws -> Any
}

fileprivate enum _DictionaryEncodingStorage {
    case value(Any)
    case container(_DictionaryEncodingContainer)
    
    func toAny() throws -> Any {
        switch self {
        case .value(let value):
            return value
        case .container(let container):
            return try container.toAny()
        }
    }
}

fileprivate final class _EncodingKeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol, _DictionaryEncodingContainer {
    typealias Key = K
    
    var codingPath: [CodingKey]
    private let options: LGDictionaryEncoder._Options
    weak var encoder: __LGDictionaryEncoder?
    
    init(codingPath: [CodingKey], options: LGDictionaryEncoder._Options, encoder: __LGDictionaryEncoder?) {
        self.codingPath = codingPath
        self.storage = [:]
        self.options = options
        self.encoder = encoder
    }
    
    private var storage: [String: _DictionaryEncodingStorage]
    
    func toAny() throws -> Any {
        return try storage.mapValues { try $0.toAny() }
    }
    
    func encodeNil(forKey key: Key) throws {
        storage[key.stringValue] = .value(Optional<Any>.none as Any)
    }
    
    func encode(_ value: Bool, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Int, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Int8, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Int16, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Int32, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Int64, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: UInt, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: UInt8, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: UInt16, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: UInt32, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: UInt64, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: String, forKey key: Key) throws {
        storage[key.stringValue] = .value(value)
    }
    
    func encode(_ value: Float, forKey key: Key) throws {
        if let result = try encoder?.box(value) {
            storage[key.stringValue] = .value(result)
        } else {
            throw EncodingError._invalidFloatingPointValue(value, at: self.codingPath)
        }
    }
    
    func encode(_ value: Double, forKey key: Key) throws {
        if let result = try encoder?.box(value) {
            storage[key.stringValue] = .value(result)
        } else {
            throw EncodingError._invalidFloatingPointValue(value, at: self.codingPath)
        }
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if let originalData = value as? Data, let resultData = try encoder?.box(originalData) {
            storage[key.stringValue] = .value(resultData)
        } else if let originalDate = value as? Date, let resultDate = try encoder?.box(originalDate) {
            storage[key.stringValue] = .value(resultDate)
        } else {
            codingPath.append(key)
            defer {
                codingPath.removeLast()
            }
            let result = try __LGDictionaryEncoder(options: self.options, codingPath: codingPath).encodeToAny(value)
            if options.dataEncodingStrategy == .codableToData, (result is [String: Any] || result is [Any]) {
                let data = try JSONSerialization.data(withJSONObject: result,
                                                      options: JSONSerialization.WritingOptions.prettyPrinted)
                storage[key.stringValue] = .value(data)
            } else {
                storage[key.stringValue] = .value(result)
            }
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key)
        -> KeyedEncodingContainer<NestedKey>
    {
        codingPath.append(key)
        defer {
            codingPath.removeLast()
        }
        let keyed = _EncodingKeyedContainer<NestedKey>(codingPath: self.codingPath,
                                                       options: self.options,
                                                       encoder: self.encoder)
        storage[key.stringValue] = .container(keyed)
        return KeyedEncodingContainer(keyed)
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        codingPath.append(key)
        defer {
            codingPath.removeLast()
        }
        let unkeyed = _EncodingUnkeyedContainer(codingPath: self.codingPath,
                                                options: self.options,
                                                encoder: self.encoder)
        storage[key.stringValue] = .container(unkeyed)
        return unkeyed
    }
    
    func superEncoder() -> Swift.Encoder {
        return superEncoder(forKey: Key(stringValue: "super")!)
    }
    
    func superEncoder(forKey key: Key) -> Swift.Encoder {
        codingPath.append(key)
        defer {
            codingPath.removeLast()
        }
        let encoder = __LGDictionaryEncoder(options: self.options, codingPath: self.codingPath)
        storage[key.stringValue] = .container(encoder)
        return encoder
    }
}

fileprivate final class _EncodingUnkeyedContainer: Swift.UnkeyedEncodingContainer, _DictionaryEncodingContainer {
    
    var codingPath: [CodingKey]
    
    private let options: LGDictionaryEncoder._Options
    
    weak var encoder: __LGDictionaryEncoder?
    
    init(codingPath: [CodingKey], options: LGDictionaryEncoder._Options, encoder: __LGDictionaryEncoder?) {
        self.codingPath = codingPath
        self.options = options
        self.encoder = encoder
    }
    
    private var storage: [_DictionaryEncodingStorage] = []
    
    func toAny() throws -> Any {
        return try storage.map { try $0.toAny() }
    }
    
    public var count: Int {
        return storage.count
    }
    
    func encodeNil() throws {
        storage.append(.value(Optional<Any>.none as Any))
    }
    
    func encode(_ value: Bool) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Int) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Int8) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Int16) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Int32) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Int64) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: UInt) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: UInt8) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: UInt16) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: UInt32) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: UInt64) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: String) throws {
        storage.append(.value(value))
    }
    
    func encode(_ value: Float) throws {
        if let result = try encoder?.box(value) {
            storage.append(.value(result))
        } else {
            throw EncodingError._invalidFloatingPointValue(value, at: self.codingPath)
        }
    }
    
    func encode(_ value: Double) throws {
        if let result = try encoder?.box(value) {
            storage.append(.value(result))
        } else {
            throw EncodingError._invalidFloatingPointValue(value, at: self.codingPath)
        }
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        if let originalData = value as? Data, let resultData = try encoder?.box(originalData) {
            storage.append(.value(resultData))
        } else if let originalDate = value as? Date, let resultDate = try encoder?.box(originalDate) {
            storage.append(.value(resultDate))
        } else {
            codingPath.append(IndexKey(intValue: count))
            defer {
                codingPath.removeLast()
            }
            let result = try __LGDictionaryEncoder(options: self.options, codingPath: codingPath).encodeToAny(value)
            storage.append(.value(result))
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        codingPath.append(IndexKey(intValue: count))
        defer {
            codingPath.removeLast()
        }
        let keyed = _EncodingKeyedContainer<NestedKey>(codingPath: self.codingPath,
                                                       options: self.options,
                                                       encoder: self.encoder)
        storage.append(.container(keyed))
        return KeyedEncodingContainer(keyed)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        codingPath.append(IndexKey(intValue: count))
        defer {
            codingPath.removeLast()
        }
        let unkeyed = _EncodingUnkeyedContainer(codingPath: self.codingPath,
                                                options: self.options,
                                                encoder: self.encoder)
        storage.append(.container(unkeyed))
        return unkeyed
    }
    
    func superEncoder() -> Swift.Encoder {
        codingPath.append(IndexKey(intValue: count))
        defer {
            codingPath.removeLast()
        }
        let encoder = __LGDictionaryEncoder(options: self.options, codingPath: self.codingPath)
        storage.append(.container(encoder))
        return encoder
    }
}

fileprivate final class _EncodingSingleContainer: SingleValueEncodingContainer, _DictionaryEncodingContainer {
    
    let codingPath: [CodingKey]
    
    private let options: LGDictionaryEncoder._Options
    
    weak var encoder: __LGDictionaryEncoder?
    
    init(codingPath: [CodingKey], options: LGDictionaryEncoder._Options, encoder: __LGDictionaryEncoder?) {
        self.codingPath = codingPath
        self.options = options
        self.encoder = encoder
    }
    
    var storage: Any?
    
    func toAny() throws -> Any {
        guard let value = storage else {
            let debugDescription = "Can not get value"
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw EncodingError.invalidValue("nil value", context)
        }
        return value
    }
    
    func encodeNil() throws {
        storage = .some(Optional<Any>.none as Any)
    }
    
    func encode(_ value: Bool) throws {
        storage = value
    }
    
    func encode(_ value: String) throws {
        storage = value
    }
    
    func encode(_ value: Double) throws {
        storage = try encoder?.box(value)
    }
    
    func encode(_ value: Float) throws {
        storage = try encoder?.box(value)
    }
    
    func encode(_ value: Int) throws {
        storage = value
    }
    
    func encode(_ value: Int8) throws {
        storage = value
    }
    
    func encode(_ value: Int16) throws {
        storage = value
    }
    
    func encode(_ value: Int32) throws {
        storage = value
    }
    
    func encode(_ value: Int64) throws {
        storage = value
    }
    
    func encode(_ value: UInt) throws {
        storage = value
    }
    
    func encode(_ value: UInt8) throws {
        storage = value
    }
    
    func encode(_ value: UInt16) throws {
        storage = value
    }
    
    func encode(_ value: UInt32) throws {
        storage = value
    }
    
    func encode(_ value: UInt64) throws {
        storage = value
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        if let originalData = value as? Data, let resultData = try encoder?.box(originalData) {
            storage = resultData
        } else if let originalDate = value as? Date, let resultDate = try encoder?.box(originalDate) {
            storage = resultDate
        } else {
            let encoder = __LGDictionaryEncoder(options: self.options, codingPath: self.codingPath)
            storage = try encoder.encodeToAny(value)
        }
    }
}

extension __LGDictionaryEncoder {
    fileprivate func box(_ float: Float) throws -> Any {
        guard !float.isInfinite && !float.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                                                throw EncodingError._invalidFloatingPointValue(float, at: codingPath)
            }
            
            if float == Float.infinity {
                return posInfString
            } else if float == -Float.infinity {
                return negInfString
            } else {
                return nanString
            }
        }
        
        return float
    }
    
    fileprivate func box(_ double: Double) throws -> Any {
        guard !double.isInfinite && !double.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                                                throw EncodingError._invalidFloatingPointValue(double, at: codingPath)
            }
            
            if double == Double.infinity {
                return posInfString
            } else if double == -Double.infinity {
                return negInfString
            } else {
                return nanString
            }
        }
        
        return double
    }
    
    fileprivate func box(_ date: Date) throws -> Any {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            // Must be called with a surrounding with(pushedKey:) call.
            // Dates encode as single-value objects; this can't both throw and push a container, so no need to catch the error.
            try date.encode(to: self)
            return date
        case .secondsSince1970:
            return date.timeIntervalSince1970
        case .millisecondsSince1970:
            return 1000.0 * date.timeIntervalSince1970
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return iso8601Formatter.string(from: date)
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
        case .formatted(let formatter):
            return formatter.string(from: date)
        }
    }
    
    fileprivate func box(_ data: Data) throws -> Any {
        switch self.options.dataEncodingStrategy {
        case .raw, .codableToData:
            return data
        case .base64:
            return data.base64EncodedData()
        }
    }
}


//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//
internal extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    static func _invalidFloatingPointValue<T : FloatingPoint>(_ value: T,
                                                              at codingPath: [CodingKey]) -> EncodingError
    {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }
        
        var debugDescription = "Unable to encode \(valueDescription) directly in Dictionary. "
        debugDescription += "Use DictionaryEncoder.NonConformingFloatEncodingStrategy.convertToString "
        debugDescription += "to specify how the value should be encoded."
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription)
        return EncodingError.invalidValue(value, context)
    }
}

//===----------------------------------------------------------------------===//
// IndexKey
//===----------------------------------------------------------------------===//
struct IndexKey: CodingKey {
    var intValue: Int? {
        return index
    }
    
    var stringValue: String {
        return "Index \(index)"
    }
    
    var index: Int
    
    init(intValue index: Int) {
        self.index = index
    }
    
    init?(stringValue: String) {
        return nil
    }
}

//===----------------------------------------------------------------------===//
// Shared ISO8601 Date Formatter, Copy From JSONDecoder
//===----------------------------------------------------------------------===//

// NOTE: This value is implicitly lazy and _must_ be lazy.
// We're compiled against the latest SDK (w/ISO8601DateFormatter), but linked against whichever Foundation the user has.
// ISO8601DateFormatter might not exist, so we better not hit this code path on an older OS.
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal var iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
