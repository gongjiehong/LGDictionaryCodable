//
//  LGDictionaryDecoderTest.swift
//  LGDictionaryCodableTests
//
//  Created by 龚杰洪 on 2019/4/25.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import XCTest
@testable import LGDictionaryCodable

class LGDictionaryDecoderTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        
        let dictionary: [String: Any] = ["title": "this is title",
                                         "date": "2012-04-21T18:25:43-05:00",
                                         "description": "this is description",
                                         "floatValue": 3.1415927,
                                         "doubleValue": 3.1415926535897932384626,
                                         "child": ["title": "this is title",
                                                   "description": "this is description",
                                                   "floatValue": 3.1415927,
                                                   "doubleValue": 3.1415926535897932384626,
                                                   "date": "2012-04-21T18:25:43-05:00"]]
        
        var counter: Int = 1
        
        repeat {
            do {
                let normalDecoder = LGDictionaryDecoder()
                normalDecoder.dateDecodingStrategy = .iso8601
                let decodedObject = try normalDecoder.decode([LGDictionaryDecoderExampleModel].self, from: [dictionary, dictionary])
//                assert(decodedObject.title == "this is title", "decode failed")
//                assert(decodedObject.child.title == "this is title", "child decode failed")
//
//                let normalEncoder = LGDictionaryEncoder()
//                normalEncoder.dateEncodingStrategy = .secondsSince1970
//                let encodedObject = try normalEncoder.encode(decodedObject)
//
                dump(decodedObject)
                
            } catch {
                dump(error)
            }
            
            counter -= 1
        } while counter >= 0
    }

    
    func testTableBind() {
        let values = ColumnTypeDecoder.types(of: LGDictionaryDecoderExampleModel.self)
        for (key, value) in values {
            print(key, value.description)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

struct LGDictionaryDecoderExampleModel : Codable {
    var title: String
    var description: String
    var date: Date
    
    var floatValue: Float
    var doubleValue: Double
    
    var child: LGDictionaryDecoderExampleChildModel
}

struct LGDictionaryDecoderExampleChildModel : Codable {
    var title: String
    var description: String
    var floatValue: Float
    var doubleValue: Double
    var date: Date
}
