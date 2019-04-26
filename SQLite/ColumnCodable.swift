//
//  ColumnCodable.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

public protocol ColumnCodable {
    static var columnType: ColumnType {get}
}

extension Int8 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Int16 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Int32 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Int64 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Int : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension UInt8 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension UInt16 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension UInt32 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension UInt64 : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension UInt : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Bool : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.integer
    }
}

extension Float : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.float
    }
}

extension Double : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.float
    }
}

extension String : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.text
    }
}

extension Data : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.BLOB
    }
}

extension Date : ColumnCodable {
    public static var columnType: ColumnType {
        return ColumnType.BLOB
    }
}

