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
                                          qos: DispatchQoS.background)
    
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
    
    public func createTable(from type: Codable.Type,
                            propertys: [ColumnProperty] = [],
                            completeCallback: ((Bool) -> Void)? = nil)
    {
        let columns = ColumnTypeDecoder.types(of: type)
        
        var createSQL: String = "CREATE TABLE IF NOT EXISTS \(type)Table ("
        
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
        
        workQueue.async {
            self.databaseQueue.inDatabase { (database) in
                let result = database.executeStatements(createSQL)
                if let completeCallback = completeCallback {
                    DispatchQueue.main.async {
                        completeCallback(result)
                    }
                }
            }
        }
    }
    
    public func insert<T>(value: T,
                          clearOld: Bool = false,
                          completeCallback: ((Bool) -> Void)? = nil) where T : Encodable
    {
        let encoder = LGDictionaryEncoder()
        do {
            let valueToInsert = try encoder.encode(value)
            
            var sql: String = "INSERT OR REPLACE INTO \(T.self)Table %@ VALUES %@ ;"
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
                do {
                    let set = try database.executeUpdate(sql, withArgumentsIn: valuesArray)
                    
                } catch {
                    print(error)
                }
            }
            
        } catch {
            print(error)
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
