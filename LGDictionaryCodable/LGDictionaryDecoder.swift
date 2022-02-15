//
//  LGDictionaryDecoder.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/25.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

open class LGDictionaryDecoder {
    // MARK: Options
    
    /// The strategy to use for decoding `Date` values. Copy from system JSONDecoder
    ///
    /// - deferredToDate: Defer to `Date` for decoding. This is the default strategy.
    /// - secondsSince1970: Decode the `Date` as a UNIX timestamp from a number.
    /// - millisecondsSince1970: Decode the `Date` as UNIX millisecond timestamp from a number.
    /// - iso8601: Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    /// - formatted: Decode the `Date` as a string parsed by the given formatter.
    /// - customthrows->Date: Decode the `Date` as a custom value decoded by the given closure.
    public enum DateDecodingStrategy {
        /// Defer to `Date` for decoding. This is the default strategy.
        case deferredToDate
        
        /// Decode the `Date` as a UNIX timestamp from a number.
        case secondsSince1970
        
        /// Decode the `Date` as UNIX millisecond timestamp from a number.
        case millisecondsSince1970
        
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    ///
    /// - raw: Raw data, no processing
    /// - asDecodableObject:
    /// - customthrows-> Decode the `Data` as a custom value decoded by the given closure.
    public enum DataDecodingStrategy {
        /// Raw data, no processing
        case raw
        
        /// Defer to `Data` for decoding.
        case deferredToData
        
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Encoded the data object to Decodable object or array.
        case dataToCodable
        
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
    
    /// The strategy to use for non-Dictionary-conforming floating-point values (IEEE 754 infinity and NaN).
    ///
    /// - `throw`: Throw upon encountering non-conforming values. This is the default strategy.
    /// - convertFromString: Decode the values from the given representation strings.
    public enum NonConformingFloatDecodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use for not contain key value
    ///
    /// - `throw`: Throw error not contain.
    /// - `default`: Use default value instead.
    public enum NonContainsKeyDecodingStrategy {
        /// Throw error not contain.
        case `throw`
        
        /// Use default value instead.
        case `default`
    }
    
    /// The strategy to use in decoding dates. Defaults to `.deferredToDate`.
    open var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    open var dataDecodingStrategy: DataDecodingStrategy = .raw
    
    /// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
    
    open var nonContainsKeyDecodingStrategy: NonContainsKeyDecodingStrategy = .throw
    
    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let nonContainsKeyDecodingStrategy: NonContainsKeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }
    
    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        return _Options(dateDecodingStrategy: dateDecodingStrategy,
                        dataDecodingStrategy: dataDecodingStrategy,
                        nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
                        nonContainsKeyDecodingStrategy: nonContainsKeyDecodingStrategy,
                        userInfo: userInfo)
    }
    
    // MARK: - Constructing a Dictionary Decoder
    /// Initializes `self` with default strategies.
    public init() {
    }
    
    // MARK: - Decoding Values
    /// Decodes a top-level value of the given type from the given Dictionary representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted,
    ///  or if the given data is not valid Dictionary.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from dictionary: Any) throws -> T {
        let topLevel = dictionary
        let decoder = __LGDictionaryDecoder(referencing: topLevel, options: self.options)
        let value = try T.init(from: decoder)
        return value
    }
}

// MARK: - DictionaryDecoder
fileprivate class __LGDictionaryDecoder : Swift.Decoder {
    // MARK: Properties
    /// The decoder's storage.
    var storage: DictionaryDecodingStorage
    
    /// Options set on the top-level decoder.
    let options: LGDictionaryDecoder._Options
    
    /// The path to the current point in encoding.
    var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    init(referencing container: Any, at codingPath: [CodingKey] = [], options: LGDictionaryDecoder._Options) {
        self.storage = DictionaryDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }
    
    // MARK: - Decoder Methods
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer is NSNull) else {
            let debugDescription = "Cannot get keyed decoding container -- found null value instead."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self, context)
        }
        
        guard let topContainer = self.storage.topContainer as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath,
                                              expectation: [String : Any].self,
                                              reality: self.storage.topContainer)
        }
        
        let container = _DictionaryKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer is NSNull) else {
            let debugDescription = "Cannot get unkeyed decoding container -- found null value instead."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
        }
        
        let topContainer = self.storage.topContainer as? [Any] ?? [self.storage.topContainer]
        return _DictionaryUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Decoding Storage
fileprivate struct DictionaryDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the Dictionary types (NSNull, NSNumber, String, Array, [String : Any]).
    private(set) public var containers: [Any] = []
    
    // MARK: - Initialization
    /// Initializes `self` with no containers.
    public init() {}
    
    // MARK: - Modifying the Stack
    public var count: Int {
        return self.containers.count
    }
    
    public var topContainer: Any {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.last!
    }
    
    mutating func push(container: Any) {
        self.containers.append(container)
    }
    
    mutating func popContainer() {
        precondition(self.containers.count > 0, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers
fileprivate struct _DictionaryKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    let decoder: __LGDictionaryDecoder
    
    /// A reference to the container we're reading from.
    let container: [String : Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: __LGDictionaryDecoder, wrapping container: [String : Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    // MARK: - KeyedDecodingContainerProtocol Methods
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }
    
    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        if let entry = self.container[key.stringValue] {
           return entry is NSNull
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                return true
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  Bool.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
        
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Int.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
        
       
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Float.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: Double.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        if let entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let value = try self.decoder.unbox(entry, as: String.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value =  type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        if var entry = self.container[key.stringValue] {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            
            if let data = (entry as? Data) {
                switch self.decoder.options.dataDecodingStrategy {
                case .dataToCodable:
                    if let tempEntry = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                        entry = tempEntry
                    }
                    break
                default:
                    break
                }
            }
            
            guard let value = try self.decoder.unbox(entry, as: T.self) else {
                let debugDescription = "Expected \(type) value but found null instead."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.valueNotFound(type, context)
            }
            
            return value
        } else {
            switch decoder.options.nonContainsKeyDecodingStrategy {
            case .`default`:
                if let value = type.defaultValue  {
                    return value
                } else {
                    fallthrough
                }
            case .throw:
                let debugDescription = "No value associated with key \(key) (\"\(key.stringValue)\")."
                let context = DecodingError.Context(codingPath: self.decoder.codingPath,
                                                    debugDescription: debugDescription)
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                           forKey key: Key) throws
        -> KeyedDecodingContainer<NestedKey>
    {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            let typeForError = KeyedDecodingContainer<NestedKey>.self
            let debugDescription = "Cannot get \(typeForError) -- no value found for key \"\(key.stringValue)\""
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.keyNotFound(key, context)
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }
        
        let container = _DictionaryKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            let keyString = key.stringValue
            let debugDescription = "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(keyString)\""
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.keyNotFound(key, context)
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }
        
        return _DictionaryUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        let value: Any = self.container[key.stringValue] ?? NSNull()
        return __LGDictionaryDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
    
    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: _DictionaryKey.super)
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

fileprivate struct _DictionaryUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: __LGDictionaryDecoder
    
    /// A reference to the container we're reading from.
    private let container: [Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: __LGDictionaryDecoder, wrapping container: [Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    var count: Int? {
        return self.container.count
    }
    
    var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }
    
    mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(Any?.self, context)
        }
        
        if self.container[self.currentIndex] is NSNull {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Unkeyed container is at end."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: T.self) else {
            let path = self.decoder.codingPath + [_DictionaryKey(index: self.currentIndex)]
            let debugDescription = "Expected \(type) but found null instead."
            let context = DecodingError.Context(codingPath: path, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
        -> KeyedDecodingContainer<NestedKey>
    {
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            let debugDescription = "Cannot get nested keyed container -- unkeyed container is at end."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, context)
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            let debugDescription = "Cannot get keyed decoding container -- found null value instead."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, context)
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }
        
        self.currentIndex += 1
        let container = _DictionaryKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            let debugDescription = "Cannot get nested keyed container -- unkeyed container is at end."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            let debugDescription = "Cannot get keyed decoding container -- found null value instead."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }
        
        self.currentIndex += 1
        return _DictionaryUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_DictionaryKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            let debugDescription = "Cannot get superDecoder() -- unkeyed container is at end."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(Decoder.self, context)
        }
        
        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return __LGDictionaryDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
}

extension __LGDictionaryDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            let debugDescription = "Expected \(type) but found null value instead."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(type, context)
        }
    }
    
    func decodeNil() -> Bool {
        return self.storage.topContainer is NSNull
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }
    
    func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }
    
    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(T.self)
        return try self.unbox(self.storage.topContainer, as: T.self)!
    }
}

// MARK: - Concrete Value Representations
fileprivate extension __LGDictionaryDecoder {
    /// Returns the given value unboxed from a container.
    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        guard !(value is NSNull) else { return nil }
        
        if let bool = value as? Bool {
            return bool
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Int {
            return number
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Int8 {
            return number
        }
        
        if let number = value as? Int {
            return Int8(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Int16 {
            return number
        }
        
        if let number = value as? Int {
            return Int16(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Int32 {
            return number
        }
        
        if let number = value as? Int {
            return Int32(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Int64 {
            return number
        }
        
        if let number = value as? Int {
            return Int64(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? UInt {
            return number
        }
        
        if let number = value as? Int, number > 0 {
            return UInt(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? UInt8 {
            return number
        }
        
        if let number = value as? Int, number > 0 {
            return UInt8(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? UInt16 {
            return number
        }
        
        if let number = value as? Int, number > 0 {
            return UInt16(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? UInt32 {
            return number
        }
        
        if let number = value as? Int, number > 0 {
            return UInt32(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? UInt64 {
            return number
        }
        
        if let number = value as? UInt {
            return UInt64(number)
        }
        
        if let number = value as? Int, number > 0 {
            return UInt64(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Float {
            return number
        }
        
        if let number = value as? Double {
            return Float(number)
        }
        
        if let number = value as? Int {
            return Float(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? Double {
            return number
        }
        
        if let number = value as? Int {
            return Double(number)
        }
        
        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func unbox(_ value: Any, as type: String.Type) throws -> String? {
        guard !(value is NSNull) else { return nil }
        
        guard let string = value as? String else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }
        
        return string
    }
    
    func unbox(_ value: Any, as type: Date.Type) throws -> Date? {
        guard !(value is NSNull) else { return nil }
        
        switch self.options.dateDecodingStrategy {
        case .deferredToDate:
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try Date(from: self)
            
        case .secondsSince1970:
            let double = try self.unbox(value, as: Double.self)!
            return Date(timeIntervalSince1970: double)
            
        case .millisecondsSince1970:
            let double = try self.unbox(value, as: Double.self)!
            return Date(timeIntervalSince1970: double / 1000.0)
            
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let string = try self.unbox(value, as: String.self)!
                guard let date = iso8601Formatter.date(from: string) else {
                    let debugDescription = "Expected date string to be ISO8601-formatted."
                    let context = DecodingError.Context(codingPath: self.codingPath,
                                                        debugDescription: debugDescription)
                    throw DecodingError.dataCorrupted(context)
                }
                
                return date
            } else {
                let debugDescription = "ISO8601DateFormatter is unavailable on this platform."
                let context = DecodingError.Context(codingPath: [], debugDescription: debugDescription)
                throw DecodingError.dataCorrupted(context)
            }
            
        case .formatted(let formatter):
            let string = try self.unbox(value, as: String.self)!
            guard let date = formatter.date(from: string) else {
                let debugDescription = "Date string does not match format expected by formatter."
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.dataCorrupted(context)
            }
            
            return date
            
        case .custom(let closure):
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try closure(self)
        }
    }
    
    func unbox(_ value: Any, as type: Data.Type) throws -> Data? {
        guard !(value is NSNull) else { return nil }
        
        switch self.options.dataDecodingStrategy {
        case .raw, .dataToCodable:
            return value as? Data
        case .deferredToData:
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try Data(from: self)
            
        case .base64:
            guard let string = value as? String else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }
            
            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }
            
            return data
            
        case .custom(let closure):
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try closure(self)
        }
        
    }
    
    func unbox(_ value: Any, as type: Decimal.Type) throws -> Decimal? {
        guard !(value is NSNull) else { return nil }
        
        // Attempt to bridge from NSDecimalNumber.
        if let decimal = value as? Decimal {
            return decimal
        } else {
            let doubleValue = try self.unbox(value, as: Double.self)!
            return Decimal(doubleValue)
        }
    }
    
    func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        let decoded: T
        if T.self == Date.self || T.self == NSDate.self {
            guard let date = try self.unbox(value, as: Date.self) else { return nil }
            decoded = date as! T
        } else if T.self == Data.self || T.self == NSData.self {
            guard let data = try self.unbox(value, as: Data.self) else { return nil }
            decoded = data as! T
        } else if T.self == URL.self || T.self == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }
            
            decoded = (url as! T)
        } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
            guard let decimal = try self.unbox(value, as: Decimal.self) else { return nil }
            decoded = decimal as! T
        } else {
            self.storage.push(container: value)
            decoded = try T(from: self)
            self.storage.popContainer()
        }
        
        return decoded
    }
}

//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
fileprivate struct _DictionaryKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    public init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
    
    public static let `super` = _DictionaryKey(stringValue: "super")!
}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//

internal extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return DecodingError.typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }
    
    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    static func _typeDescription(of value: Any) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}

