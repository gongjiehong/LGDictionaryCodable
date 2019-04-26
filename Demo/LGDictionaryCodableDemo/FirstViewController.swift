//
//  FirstViewController.swift
//  LGDictionaryCodableDemo
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import UIKit
import LGDictionaryCodable

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let dbManager = LGDBManager(dbName: "test", directory: LGDBManager.Directory.documents)
        dbManager.createTable(from: LGDictionaryDecoderExampleModel.self,
                              propertys: [ColumnProperty(name: "title",
                                                         defaultValue: "",
                                                         isUnique: false,
                                                         isPrimary: true)])
        { (succeed) in
                                                            
        }
        
        let childModel = LGDictionaryDecoderExampleChildModel(title: "title",
                                                              description: "description",
                                                              floatValue: 3.1415926,
                                                              doubleValue: 3.1415926535897932384626,
                                                              date: Date())
        let model = LGDictionaryDecoderExampleModel(title: "title",
                                                    description: "description",
                                                    date: Date(),
                                                    floatValue: 3.1415927,
                                                    doubleValue: 3.1415926535897932384626,
                                                    child: childModel)
        dbManager.insert(value: model, clearOld: true)
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
