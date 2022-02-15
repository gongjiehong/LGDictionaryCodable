//
//  LGDecodableDefaultValue.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/6/5.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

// MARK: - Decodable object contain a defualt value 
extension Decodable {
    public static var defaultValue: Self? {
        // 此处特殊处理Array类型，如果为Array可以成功转换，不是的话会返回nil，不影响其它类型处理，解析效率有一定影响
        return [] as? Self
    }
}

extension Encodable {
    public static var defaultValue: Self? {
        return nil
    }
}

extension Int {
    public static var defaultValue: Int? {
        return 0
    }
}

extension Int8 {
    public static var defaultValue: Int8? {
        return 0
    }
}

extension Int16 {
    public static var defaultValue: Int16? {
        return 0
    }
}

extension Int32 {
    public static var defaultValue: Int32? {
        return 0
    }
}

extension Int64 {
    public static var defaultValue: Int64? {
        return 0
    }
}

extension UInt {
    public static var defaultValue: UInt? {
        return 0
    }
}

extension UInt8 {
    public static var defaultValue: UInt8? {
        return 0
    }
}

extension UInt16 {
    public static var defaultValue: UInt16? {
        return 0
    }
}

extension UInt32 {
    public static var defaultValue: UInt32? {
        return 0
    }
}

extension UInt64 {
    public static var defaultValue: UInt64? {
        return 0
    }
}

extension Float {
    public static var defaultValue: Float? {
        return 0.0
    }
}

extension Double {
    public static var defaultValue: Double? {
        return 0.0
    }
}

extension Bool {
    public static var defaultValue: Bool? {
        return false
    }
}

extension String {
    public static var defaultValue: String? {
        return ""
    }
}

extension Date {
    public static var defaultValue: Date? {
        return Date()
    }
}

extension Data {
    public static var defaultValue: Data? {
        return Data()
    }
}
