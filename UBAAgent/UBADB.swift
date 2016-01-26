//
//  UBADB.swift
//  UBAAgent
//
//  Created by hwh on 16/1/22.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import Foundation
import SQLite

let shareDB = UBADB()
typealias UploadHandle = (events: [Event],page: Int, complete: Bool) -> ()
class UBADB : NSObject{
    let dbQueue = NSOperationQueue()
    let backUpQueue = NSOperationQueue()
    
    private static var documentsDirectory:String {
        #if DEBUG
            let deviceID = UIDevice.currentDevice().identifierForVendor?.UUIDString
            return NSHomeDirectory().stringByAppendingString("/Documents/\(deviceID!).sqlite3")
        #else
            let deviceID = UIDevice.currentDevice().identifierForVendor?.UUIDString
            return NSHomeDirectory().stringByAppendingString("/Documents/.\(deviceID!).sqlite3")
        #endif
        
    }
    var _maxUploadLimitCount: NSInteger = 1
    
    let db = try! Connection(documentsDirectory)
    
    let events = Table("events")
    let events_backup = Table("events_backup")
   
    let id =  Expression<Int64>(EventsColumnName.id)
    let eventId = Expression<String>(EventsColumnName.eventId)
    let label =  Expression<String?>(EventsColumnName.label)
    let create_at = Expression<NSTimeInterval>(EventsColumnName.create_at)
    let update_at =  Expression<NSTimeInterval>(EventsColumnName.update_at)
    let identify  = Expression<String>(EventsColumnName.identify)
    let type      = Expression<String>(EventsColumnName.type)
    
    private var _uploadEventsBlock: UploadHandle?
    private var _uploading: Bool =  false
    
    var count:Int = 1
    
    override init() {
        PrintLog("检查表是否创建")
        PrintLog(UBADB.documentsDirectory)
        
        super.init()
        #if DEBUG
            db.trace(print)
            if _mem_db != nil {
                _mem_db?.trace(print)
            }
        #endif
        db.busyTimeout = 5//执行事务超时时间
        db.busyHandler { (tries) -> Bool in //尝试次数

            if tries > 3 {
                print("[UBA]连接数据库尝试次数大于3次，中断")
                return false
            }
            return true
        }
        try! db.run(events.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .Autoincrement)
            t.column(eventId)
            t.column(label)
            t.column(create_at)
            t.column(update_at)
            t.column(identify)
            t.column(type)
            }
        )
        try! db.run(events_backup.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .Autoincrement)
            t.column(eventId, defaultValue: "")
            t.column(label)
            t.column(create_at)
            t.column(update_at)
            t.column(identify)
            t.column(type)
            }
        )
        dbQueue.maxConcurrentOperationCount = 1 //串行执行
        
        backUpMemeryDB()//备份下之前没上传成功的备份
    }
    deinit {
    }
    
    /// 访问单例 private
    class var ShareInstance: UBADB {
        return shareDB
    }
    
}
// MARK: - 类方法
extension UBADB {
    class func InsertEvent(event: Event) {
        PrintLog("\(__FUNCTION__)")
        let operation = NSBlockOperation { () -> Void in
            shareDB.insertEvent(event)
        }
        operation.queuePriority = .Normal
        ShareInstance.dbQueue.addOperation(operation)
    }
    class func BackUpTempDB() {
        PrintLog("\(__FUNCTION__)")
        ShareInstance.backUpMemeryDB()
    }
    
    class func GetEvents(uploadBlock: UploadHandle? = nil) {
        ShareInstance.uploadEvents(uploadBlock)
    }
    class func Next() {
        ShareInstance.nextBatchEvents()
    }
}

// MARK: - Instance Methed
extension UBADB {
    /**
     备份表迁移
     */
    func backUpMemeryDB() {
        if self._uploading {
            PrintLog("正在上传所有事件，请等待",level: .Error)
            return
        }
        
        let block:() -> () = { () -> Void in
            do {
                self.backUpQueue.suspended = true
                
                try self.db.transaction { [unowned self]() -> Void in
                    PrintLog("进入 事务 并 暂停 备份数据库操作")
                    let count = self.db.scalar(self.events_backup.count)
                    PrintLog("待 迁移 \(count) 条数据")
                    let columns = "\(EventsColumnName.eventId),\(EventsColumnName.label),\(EventsColumnName.create_at),\(EventsColumnName.update_at),\(EventsColumnName.identify),\(EventsColumnName.type)"
                    try self.db.execute("INSERT INTO events(\(columns)) SELECT \(columns) FROM events_backup")
                    try self.db.run(self.events_backup.delete())
                }
                self.backUpQueue.suspended = false
                
                PrintLog("结束 memory 事务 并 打开 备份数据库操作")
            }catch {
                self.backUpQueue.suspended = false
                PrintLog("打开备份数据库操作 || memory db 迁移 error \(error)）",level: .Error)
            }
        }
        
        let operation = NSBlockOperation(block: block)
        operation.queuePriority = .High
        dbQueue.addOperation(operation)
    }
    func getRowsFromTable(start: NSInteger) -> [AnyObject]? {
        if start == NSNotFound {
            return nil
        }
        events.limit(_maxUploadLimitCount, offset: start)
        return  nil
    }
    func insertEvent(event: Event) {
        let block:()-> () = { [unowned self]() -> Void in
            do {
                event.update_at = NSDate.currentDateStamp()
                
                try self.db.run(self.events_backup.insert(self.eventId <- event.self._eventId, self.label <- event.self._label,self.identify <- event.self.identify, self.create_at <- event.self.create_at, self.update_at <- event.self.update_at ,self.type <- event.type.rawValue))
                
                PrintLog("插入 执行成功")
            }catch  {
                PrintLog("插入 数据库 出错 \(error)",level: .Error)
            }
        }
        let operation = NSBlockOperation(block: block)
        backUpQueue.addOperation(operation)
    }
    
    func uploadEvents(uploadBlock: UploadHandle?)  {
        let block = {[unowned self] () -> Void in
            self._uploadEventsBlock =  uploadBlock
            var _events = [Event]()
            
            var pre100Events: [Row]
            
            if uploadBlock != nil {
                pre100Events = try! Array(self.db.prepare(self.events.limit(self._maxUploadLimitCount)))
            }else {
                //获取所有
                pre100Events = try! Array(self.db.prepare(self.events))
            }
            self._uploading = pre100Events.count > 0

            if let _block = self._uploadEventsBlock{
                for one in pre100Events {
                    let e = Event(id: one[self.eventId], label: one[self.label])
                    e.identify = one[self.identify]
                    e.create_at = one[self.create_at]
                    e.update_at = one[self.update_at]
                    e.type      = EventType(rawValue: one[self.type])!
                    
                    _events.append(e)
                }
                
                _block(events: _events,page: Int(self.count),complete: !self._uploading)
            }
            self.count++

        }
        let  operation = NSBlockOperation(block: block)
        dbQueue.addOperation(operation)
    }
    func nextBatchEvents() {
        self._uploading = false
        do {
            try db.execute("delete from events where id in (select id from events limit \(_maxUploadLimitCount))")
            if _uploadEventsBlock != nil {
                uploadEvents(_uploadEventsBlock!)
            }
        }catch {
            PrintLog("删除失败 \(__FUNCTION__)\(error)")
            return;
        }
        
    }
}