//
//  ColumnTypeDecoder.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

public final class ColumnTypeDecoder : Swift.Decoder {
    fileprivate var results: [String: ColumnType] = [:]
    
    static func types(of type: Decodable.Type) -> [String: ColumnType] {
        let decoder = ColumnTypeDecoder()
        _ = try? type.init(from: decoder)
        return decoder.results
    }
    
    public var codingPath: [CodingKey] {
        fatalError("It should not be called.")
    }
    
    public var userInfo: [CodingUserInfoKey : Any] {
        fatalError("It should not be called.")
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(_ColumnTypeDecodingContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("It should not be called.")
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("It should not be called.")
    }
}

fileprivate final class _ColumnTypeDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] {
        fatalError("It should not be called.")
    }
    
    var allKeys: [K] {
        fatalError("It should not be called.")
    }
    
    private var decoder: ColumnTypeDecoder
    
    
    init(decoder: ColumnTypeDecoder) {
        self.decoder = decoder
        sizedPointers = ContiguousArray<SizedPointer>()
    }
    
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        decoder.results[key.stringValue] = Bool.columnType
        return false
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        decoder.results[key.stringValue] = Bool.columnType
        return false
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        decoder.results[key.stringValue] = type.columnType
        return ""
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        decoder.results[key.stringValue] = type.columnType
        return 0.0
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        decoder.results[key.stringValue] = type.columnType
        return 0.0
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        decoder.results[key.stringValue] = type.columnType
        return 0
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        if type is ColumnCodable.Type {
            decoder.results[key.stringValue] = (type as! ColumnCodable.Type).columnType
        } else {
            decoder.results[key.stringValue] = ColumnType.BLOB
        }
        
        let sizedPointer = SizedPointer(of: T.self)
        sizedPointers.append(sizedPointer)
        return sizedPointer.getPointee()
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws
        -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey
    {
        fatalError("It should not be called.")
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError("It should not be called.")
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("It should not be called.")
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        fatalError("It should not be called.")
    }
    
    typealias Key = K
    
    deinit {
        for value in sizedPointers {
            value.deallocate()
        }
    }
    
    private var sizedPointers: ContiguousArray<SizedPointer>
    
    private struct SizedPointer {
        private let pointer: UnsafeMutableRawPointer
        
        private let size: Int
        
        init<T>(of type: T.Type = T.self) {
            size = MemoryLayout<T>.size
            pointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 1)
            memset(pointer, 0, size)
        }
        
        func deallocate() {
            pointer.deallocate()
        }
        
        func getPointee<T>(of type: T.Type = T.self) -> T {
            return pointer.assumingMemoryBound(to: type).pointee
        }
    }
    
}
