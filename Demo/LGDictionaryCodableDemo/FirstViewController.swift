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
        dbManager.createTable(from: LGDictionaryDecoderExampleModel.self)
        { (succeed) in
                                                            
        }
        
        let childModel = LGDictionaryDecoderExampleChildModel(title: "title",
                                                              description: "description",
                                                              floatValue: 3.1415926,
                                                              doubleValue: 3.1415926535897932384626,
                                                              date: Date())
        let model1 = LGDictionaryDecoderExampleModel(user_id: "1",
                                                    title: "title",
                                                    description: "description",
                                                    date: Date(),
                                                    floatValue: 3.1415927,
                                                    doubleValue: 3.1415926535897932384626,
                                                    child: [childModel, childModel, childModel])
        let model2 = LGDictionaryDecoderExampleModel(user_id: "2",
                                                     title: "title",
                                                     description: "description",
                                                     date: Date(),
                                                     floatValue: 3.1415927,
                                                     doubleValue: 3.1415926535897932384626,
                                                     child: [childModel, childModel, childModel])
        let model3 = LGDictionaryDecoderExampleModel(user_id: "3",
                                                     title: "title",
                                                     description: "description",
                                                     date: Date(),
                                                     floatValue: 3.1415927,
                                                     doubleValue: 3.1415926535897932384626,
                                                     child: [childModel, childModel, childModel])
        let model4 = LGDictionaryDecoderExampleModel(user_id: "4",
                                                     title: "title",
                                                     description: "description",
                                                     date: Date(),
                                                     floatValue: 3.1415927,
                                                     doubleValue: 3.1415926535897932384626,
                                                     child: [childModel, childModel, childModel])
        let model5 = LGDictionaryDecoderExampleModel(user_id: "5",
                                                     title: "title",
                                                     description: "description",
                                                     date: Date(),
                                                     floatValue: 3.1415927,
                                                     doubleValue: 3.1415926535897932384626,
                                                     child: [childModel, childModel, childModel])
        let model6 = LGDictionaryDecoderExampleModel(user_id: "6",
                                                     title: "title",
                                                     description: "description",
                                                     date: Date(),
                                                     floatValue: 3.1415927,
                                                     doubleValue: 3.1415926535897932384626,
                                                     child: [childModel, childModel, childModel])
        dbManager.insert(values: [model1, model2, model3, model4, model5, model6])
        
        dbManager.update(to: LGDictionaryDecoderExampleModel.self,
                         values: [ColumnCondition(name: "user_id",
                                                  value: "7")],
                         wheres: ColumnCondition(name: "user_id",
                                                 value: "6"))
        { (succeed) in
                                                    
        }
        
        dbManager.select(from: LGDictionaryDecoderExampleModel.self,
                         orderBy: ColumnSortType.desc(name: "user_id"))
        { (resultArray) in
            
        }

//        let newDBManager = LGDBManager(dbName: "test", directory: LGDBManager.Directory.documents)
        
    }


}


struct LGDictionaryDecoderExampleModel : Codable {
    var user_id: String
    var title: String
    var description: String
    var date: Date
    
    var floatValue: Float
    var doubleValue: Double
    
    var child: [LGDictionaryDecoderExampleChildModel]
}

struct LGDictionaryDecoderExampleChildModel : Codable {
    var title: String
    var description: String
    var floatValue: Float
    var doubleValue: Double
    var date: Date
}
