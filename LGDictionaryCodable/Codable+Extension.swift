//
//  Codable+Extension.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/5/5.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation


public extension Encodable {
    var lg_dictionary: [String: Any]? {
        let encoder = LGDictionaryEncoder()
        let result = try? encoder.encode(self)
        return result as? [String : Any]
    }
    
    var lg_array: [Any]? {
        let encoder = LGDictionaryEncoder()
        let result = try? encoder.encode(self)
        return result as? [Any]
    }
}

public enum LGCodableError: Error {
    case canNotGetOriginalDictionary
}

public extension Decodable where Self: Encodable {
    func update(_ dictionary: [String: Any]) throws -> Codable  {
        guard var originalDictionary = self.lg_dictionary else {
            throw LGCodableError.canNotGetOriginalDictionary
        }
        originalDictionary.merge(dictionary) { (current, new) -> Any in
            return new
        }
        let decoder = LGDictionaryDecoder()
        return try decoder.decode(type(of: self), from: originalDictionary)
    }
}
