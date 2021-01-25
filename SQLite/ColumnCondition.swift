//
//  ColumnCondition.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/29.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation


public struct ColumnCondition {
    public var name: String
    public var value: Any
    public var `operator`: String
    
    public init(name: String, value: Any, `operator`: String = "=") {
        self.name = name
        self.value = value
        self.operator = `operator`
    }
}
