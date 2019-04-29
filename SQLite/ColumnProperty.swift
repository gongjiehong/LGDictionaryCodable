//
//  ColumnProperty.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation


public struct ColumnProperty {
    public var name: String
    public var isPrimary: Bool
    public var isUnique: Bool
    public var value: Any
    
    public init(name: String,
                value: Any,
                isUnique: Bool = false,
                isPrimary: Bool = false)
    {
        self.name = name
        self.value = value
        self.isUnique = isUnique
        self.isPrimary = isPrimary
    }
}
