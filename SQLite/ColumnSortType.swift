//
//  ColumnSortType.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/29.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

/// Database query sorting method
///
/// - asc: Ascending
/// - desc: Descending
public enum ColumnSortType {
    /// Ascending with column name
    case asc(name: String)
    
    /// Descending with column name
    case desc(name: String)
    
    /// Ignore and do nothing
    case ignore
}
