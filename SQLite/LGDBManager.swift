//
//  LGDBManager.swift
//  LGDictionaryCodable
//
//  Created by 龚杰洪 on 2019/4/26.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation
import FMDB

open class LGDBManager {
    static var queueDictionary = LGWeakValueDictionary<URL, FMDatabaseQueue>()
    
    private let workQueue = DispatchQueue(label: "cxylg.framework.LGDictionaryCodable.LGDBManager.workQuque",
                                          qos: DispatchQoS.userInteractive)
    
    public enum Directory {
        case documents
        case cache
        case tmp
    }
    
    private var databaseQueue: FMDatabaseQueue
    
    public init(dbName: String, directory: Directory = .documents) {
        var pathURL: URL
        switch directory {
        case .documents:
            pathURL = FileManager.lg_documentsDirectoryURL
        case .cache:
            pathURL = FileManager.lg_cacheDirectoryURL
        case .tmp:
            pathURL = FileManager.lg_temporaryDirectoryURL
        }
        
        pathURL.appendPathComponent("LGDBManager", isDirectory: true)
        FileManager.createDirectory(withURL: pathURL)
        pathURL.appendPathComponent("\(dbName).db", isDirectory: false)
        
        if FileManager.default.fileExists(atPath: pathURL.path) {
        } else {
            FileManager.default.createFile(atPath: pathURL.path, contents: nil, attributes: nil)
        }
        
        if let queue = LGDBManager.queueDictionary[pathURL] {
            self.databaseQueue = queue
        } else if let queue = FMDatabaseQueue(url: pathURL) {
            self.databaseQueue = queue
            LGDBManager.queueDictionary[pathURL] = queue
        } else {
            fatalError("Can not create FMDatabaseQueue from URL \(pathURL).")
        }
    }
    
    private func getTableName(from type: Codable.Type) -> String {
//        let tempValue = Optional<Codable.Type>(type).unsafelyUnwrapped
        return String(reflecting: type).replacingOccurrences(of: ".", with: "") + "Table"
    }
    
    public func tableExists<T>(_ type: T.Type) -> Bool where T : Codable {
        let tableName = getTableName(from: type)
        var result: Bool = false
        self.databaseQueue.inDatabase { (database) in
            result = database.tableExists(tableName)
        }
        return result
    }
    
    public func createTable<T>(from type: T.Type,
                               isAsynchronous: Bool = true,
                               propertys: [ColumnProperty] = [],
                               completeCallback: ((Bool) -> Void)? = nil) where T : Codable
    {
        func createTable() {
            let columns = ColumnTypeDecoder.types(of: type)
            
            var createSQL: String = "CREATE TABLE IF NOT EXISTS \(getTableName(from: type)) ("
            
            for (key, value) in columns {
                createSQL += (key + " ")
                
                
                let resultArray = propertys.filter { (temp) -> Bool in
                    return temp.name == key
                }
                
                if resultArray.count > 0, let property = resultArray.first {
                    if property.isPrimary {
                        createSQL += (value.description + " PRIMARY KEY, ")
                    } else if property.isUnique {
                        createSQL += (value.description + " UNIQUE, ")
                    }
                } else {
                    createSQL += (value.description + ", ")
                }
            }
            
            createSQL.removeLast()
            createSQL.removeLast()
            
            createSQL += ");"
            
            self.databaseQueue.inDatabase { (database) in
                let result = database.executeStatements(createSQL)
                if let completeCallback = completeCallback {
                    DispatchQueue.main.async {
                        completeCallback(result)
                    }
                }
            }
        }
        
        if isAsynchronous {
            workQueue.async {
                createTable()
            }
        } else {
            createTable()
        }
    }
    
    public func insert<T>(value: T,
                          clearOld: Bool = false,
                          completeCallback: ((Bool) -> Void)? = nil) where T : Codable
    {
        func callbackOnMainQueue(_ result: Bool) {
            if let completeCallback = completeCallback {
                DispatchQueue.main.async {
                    completeCallback(result)
                }
            }
        }
        
        if clearOld {
            self.delete(from: T.self)
        }
        
        workQueue.async {
            
            let encoder = LGDictionaryEncoder()
            encoder.dataEncodingStrategy = .codableToData
            encoder.dateEncodingStrategy = .secondsSince1970
            do {
                let valueToInsert = try encoder.encode(value)
                
                let tableName = self.getTableName(from: T.self)
                
                var sql: String = "INSERT OR REPLACE INTO \(tableName) %@ VALUES %@;"
                var keySql: String = "("
                var valueSql: String = "("
                
                var valuesArray = [Any]()
                
                if let dic = valueToInsert as? [String: Any] {
                    for (key, value) in dic {
                        keySql += String(format: "%@,", key)
                        valueSql += "?,"
                        valuesArray.append(value)
                    }
                    
                    keySql.removeLast()
                    keySql += ")"
                    
                    valueSql.removeLast()
                    valueSql += ")"
                }
                
                sql = String(format: sql, keySql, valueSql)
                
                self.databaseQueue.inDatabase { (database) in
                    let result = database.executeUpdate(sql, withArgumentsIn: valuesArray)
                    callbackOnMainQueue(result)
                }
            } catch {
                callbackOnMainQueue(false)
                print(error)
            }
        }
    }
    
    public func insert<T>(values: [T],
                          clearOld: Bool = false,
                          completeCallback: ((Bool) -> Void)? = nil) where T : Codable
    {
        func callbackOnMainQueue(_ result: Bool) {
            if let completeCallback = completeCallback {
                DispatchQueue.main.async {
                    completeCallback(result)
                }
            }
        }
        
        if clearOld {
            self.delete(from: T.self)
        }
        
        workQueue.async {
            let encoder = LGDictionaryEncoder()
            encoder.dataEncodingStrategy = .codableToData
            encoder.dateEncodingStrategy = .secondsSince1970

            do {
                
                let valuesToInsert = try encoder.encode(values)
                guard let arrayToInsert = valuesToInsert as? [[String: Any]], let dic = arrayToInsert.first else {
                    print("Values to insert \(values) is invalid!")
                    return
                }
                
                let keysArray = dic.keys
                
                let tableName = self.getTableName(from: T.self)
                var sql: String = "INSERT OR REPLACE INTO \(tableName) %@ VALUES %@;"
                let keySql = "(\(keysArray.joined(separator: ", ")))"
                
                let questionMarkArray = [String](repeating: "?", count: keysArray.count)
                var valuesPlaceholaderArray = [String]()
                
                var valuesArray = [Any]()
                
                for tempDic in arrayToInsert {
                    for key in keysArray {
                        if let value = tempDic[key] {
                            valuesArray.append(value)
                        } else {
                            valuesArray.append("")
                        }
                    }
                    valuesPlaceholaderArray.append("(\(questionMarkArray.joined(separator: ",")))")
                }
                
                let valuesSql = "\(valuesPlaceholaderArray.joined(separator: ", "))"
                sql = String(format: sql, keySql, valuesSql)
                self.databaseQueue.inDatabase { (database) in
                    let result = database.executeUpdate(sql, withArgumentsIn: valuesArray)
                    callbackOnMainQueue(result)
                }
            } catch {
                callbackOnMainQueue(false)
                print(error)
            }
        }
    }
    
    public func delete<T>(from type: T.Type,
                          conditions: [ColumnCondition] = [],
                          completeCallback: ((Bool) -> Void)? = nil) where T : Codable
    {
        func callbackOnMainQueue(_ result: Bool) {
            if let completeCallback = completeCallback {
                DispatchQueue.main.async {
                    completeCallback(result)
                }
            }
        }
        
        workQueue.async {
            let tableName = self.getTableName(from: type)
            var sql = "DELETE FROM \(tableName) %@;"
            var conditionValueArray = [Any]()
            if conditions.count > 0 {
                var condition = "WHERE "
                var conditionSQLArray = [String]()
                for condition in conditions {
                    conditionSQLArray.append("\(condition.name) = ?")
                    conditionValueArray.append(condition.value)
                }
                condition += conditionSQLArray.joined(separator: " AND ")
                sql = String(format: sql, condition)
            } else {
                sql = String(format: sql, "")
            }
            
            self.databaseQueue.inDatabase({ (database) in
                let result = database.executeUpdate(sql, withArgumentsIn: conditionValueArray)
                callbackOnMainQueue(result)
            })
        }
    }
    
    public func select<T>(from type: T.Type,
                          conditions: [ColumnCondition] = [],
                          orderBy: ColumnSortType = .ignore,
                          limit: ColumnLimit = .unlimited,
                          completeCallback: @escaping (([T]) -> Void)) where T : Codable
    {
        func callbackOnMainQueue(_ result: [T]) {
            DispatchQueue.main.async {
                completeCallback(result)
            }
        }
        
        workQueue.async {
            let tableName = self.getTableName(from: type)
            var sql = "SELECT * FROM \(tableName) %@ "
            
            var conditionValueArray = [Any]()
            if conditions.count > 0 {
                var condition = "WHERE "
                var conditionSQLArray = [String]()
                for condition in conditions {
                    conditionSQLArray.append("\(condition.name) = ?")
                    conditionValueArray.append(condition.value)
                }
                condition += conditionSQLArray.joined(separator: " AND ")
                sql = String(format: sql, condition)
            } else {
                sql = String(format: sql, "")
            }
            
            switch orderBy {
            case .ignore:
                break
            case .asc(name: let name):
                sql += " ORDER BY \(name) ASC"
                break
            case .desc(name: let name):
                sql += " ORDER BY \(name) DESC"
                break
            }
            
            switch limit {
            case .unlimited:
                sql += ";"
                break
            case .limit(let limit):
                sql += " LIMIT \(limit);"
                break
            }
            
            
            self.databaseQueue.inDatabase({ (database) in
                if let result = database.executeQuery(sql, withArgumentsIn: conditionValueArray) {
                    var resultDictionaryArray = [[String: Any]]()
                    while result.next() {
                        if let dictionary = result.resultDictionary as? [String: Any] {
                            resultDictionaryArray.append(dictionary)
                        }
                    }
                    
                    if resultDictionaryArray.count > 0 {
                        let decoder = LGDictionaryDecoder()
                        decoder.dataDecodingStrategy = .dataToCodable
                        decoder.dateDecodingStrategy = .secondsSince1970
                        decoder.nonContainsKeyDecodingStrategy = .default
                        do {
                            let resultArray = try decoder.decode([T].self, from: resultDictionaryArray)
                            callbackOnMainQueue(resultArray)
                        } catch {
                            callbackOnMainQueue([])
                        }
                    } else {
                        callbackOnMainQueue([])
                    }
                } else {
                    callbackOnMainQueue([])
                }
            })
        }
    }
    
    public func update<T>(to type: T.Type,
                          values: [ColumnCondition],
                          wheres: ColumnCondition,
                          completeCallback: ((Bool) -> Void)? = nil) where T : Codable
    {
        func callbackOnMainQueue(_ result: Bool) {
            if let completeCallback = completeCallback {
                DispatchQueue.main.async {
                    completeCallback(result)
                }
            }
        }
        
        workQueue.async {
            assert(values.count > 0, "values for update is invalid")
            let tableName = self.getTableName(from: type)
            var sql = "UPDATE \(tableName) SET %@ %@;"
            
            var conditionArray = [String]()
            var conditionValuesArray = [Any]()
            
            for value in values {
                conditionArray.append("\(value.name) = ?")
                conditionValuesArray.append(value.value)
                
            }
            let setValueSql = conditionArray.joined(separator: ",")
            
            sql = String(format: sql, setValueSql, "WHERE \(wheres.name) = ?")
            conditionValuesArray.append(wheres.value)
            
            self.databaseQueue.inDatabase({ (database) in
                let result = database.executeUpdate(sql, withArgumentsIn: conditionValuesArray)
                callbackOnMainQueue(result)
            })
        }
    }
}

fileprivate extension FileManager {
    static var lg_cacheDirectoryPath: String {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true)[0]
    }
    
    static var lg_cacheDirectoryURL: URL {
        return URL(fileURLWithPath: lg_cacheDirectoryPath)
    }
    
    static var lg_temporaryDirectoryPath: String {
        return NSTemporaryDirectory()
    }
    
    static var lg_temporaryDirectoryURL: URL {
        return URL(fileURLWithPath: lg_temporaryDirectoryPath)
    }
    
    static var lg_documentsDirectoryPath: String {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true)[0]
    }
    
    static var lg_documentsDirectoryURL: URL {
        return URL(fileURLWithPath: lg_documentsDirectoryPath)
    }
    
    static func createDirectory(withURL url: URL) {
        var isDirectory: ObjCBool = true
        do {
            if !FileManager.default.fileExists(atPath: url.path,
                                               isDirectory: &isDirectory)
            {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } else {
                if !isDirectory.boolValue {
                    try FileManager.default.removeItem(at: url)
                    try FileManager.default.createDirectory(at: url,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                } else {
                    // do nothing
                }
            }
        } catch {
            debugPrint(error)
        }
    }
}
