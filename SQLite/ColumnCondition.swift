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
    
    public init(name: String, value: Any) {
        self.name = name
        self.value = value
    }
}
