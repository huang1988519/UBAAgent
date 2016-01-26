//
//  UBAHelper.swift
//  UBAAgent
//
//  Created by hwh on 16/1/22.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import Foundation
import CryptoSwift

extension NSDate {
    class func currentDateStamp() -> NSTimeInterval {
        return  NSDate().timeIntervalSince1970
    }
    class func stringWithDateFormat(dateFormat: String) -> String {
        let  date = NSDate()
        let format = NSDateFormatter()
        format.dateFormat = dateFormat
        return format.stringFromDate(date)
    }
}
struct Helper {
    static func IdentifyForStamp(stamp: NSTimeInterval) -> String {
        let deveiceId = UIDevice.currentDevice().identifierForVendor?.UUIDString
        let identify = "\(deveiceId)\(stamp)"

        return identify.md5()
    }
}

let userdefault = NSUserDefaults.standardUserDefaults()
func UA_SetObject(obejct: AnyObject ,forKey: String ) {
    userdefault.setObject(obejct, forKey: forKey)
    userdefault.synchronize()
}
func UA_ObjectForKey(key: String) -> AnyObject? {
    let value = userdefault.objectForKey(key)
    return value
}
//常量
struct Constant {
    struct UserDefaultKey {
        static let enterbackGroundDateKey = "enterbackGroundDate"
        static let enableLogKey = "enableLogKey"

        static let uploadMaxLimitCountKey = "uploadMaxLimitCountKey"
    }
}

//MARK: -- Thread
//自定义 异步线程
func dispatch_async(block: dispatch_block_t) {
    if NSThread.isMainThread() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            block()
        }
    }else {
        block()
    }
}
//自定义 主线程 
func dispatch_async_safe_main(block: dispatch_block_t) {
    if NSThread.isMainThread() {
        block()
    }else {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            block()
        })
    }
}
//MARK: Log
//MARK: - Helper
enum UBALogLevel: String {
    case INFO  = "INFO"
    case Debug    = "DEBUG"
    case Warmming = "WARM"
    case Error    = "ERROR"
}

//打印 UBA Log
let _logGroup = dispatch_queue_create("log queue", DISPATCH_QUEUE_SERIAL)
func PrintLog(log: AnyObject, level: UBALogLevel? = nil) {
    let enableLog = userdefault.boolForKey(Constant.UserDefaultKey.enableLogKey)
    
    if enableLog {
        let _level = level ?? .INFO
        dispatch_async(_logGroup, { () -> Void in
            NSLog("[UBA][\(_level.rawValue)]\(log)")
        })
    }
}