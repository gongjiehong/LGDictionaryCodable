//
//  ColumnType.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

public enum ColumnType {
    case integer
    case text
    case float
    case BLOB
    case null
}

extension ColumnType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .integer:
            return "INTEGER"
        case .float:
            return "REAL"
        case .text:
            return "TEXT"
        case .BLOB:
            return "BLOB"
        case .null:
            return "NULL"
        }
    }
}
