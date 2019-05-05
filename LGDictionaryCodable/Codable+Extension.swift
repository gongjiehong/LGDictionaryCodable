//
//  Codable+Extension.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/5/5.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation


extension Encodable {
    public var lg_dictionary: [String: Any]? {
        let encoder = LGDictionaryEncoder()
        let result = try? encoder.encode(self)
        return result as? [String : Any]
    }
    
    public var lg_array: [Any]? {
        let encoder = LGDictionaryEncoder()
        let result = try? encoder.encode(self)
        return result as? [Any]
    }
}
