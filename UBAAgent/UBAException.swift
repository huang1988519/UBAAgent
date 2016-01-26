//
//  UBAException.swift
//  UBAAgent
//
//  Created by hwh on 16/1/25.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import Foundation

struct UBAException {
    
    static let name             = "name"
    static let reason           = "reason"
    static let userInfo         = "useInfo"
    static let callStackSymbols = "callStackSymbols"
    
    static var filePath:String  {
        let _path =  NSHomeDirectory().stringByAppendingString("/Documents/.Exception")
        if NSFileManager.defaultManager().fileExistsAtPath(_path) ==  false {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(_path, withIntermediateDirectories: true, attributes: nil)
            }catch {
                PrintLog("\(error)")
            }
        }

        return  _path
    }
    init() {
        PrintLog("exception path : \(UBAException.filePath)")
    }
    func EnableException() {
        
        let handle: ((@convention(c) (NSException) -> Void))? = NSGetUncaughtExceptionHandler()
        if handle != nil {
            PrintLog("外部检查到 有捕获 Excption 操作，拦截了")
        }
        NSSetUncaughtExceptionHandler { (exception) -> Void in
            
            PrintLog("系统日志 \(exception) call thread \(exception.name)")
            var errorLog = [String: AnyObject]()
            errorLog[UBAException.name] = exception.name
            errorLog[UBAException.reason] = exception.reason
            errorLog[UBAException.userInfo] = exception.userInfo
            errorLog[UBAException.callStackSymbols] = exception.callStackSymbols
            
            let dic = errorLog as NSDictionary
            let date = NSDate.stringWithDateFormat("YYYY_MM_dd_hh_mm_ss")
            let path = UBAException.filePath + "/" + date + ".log"
            
            let data = NSKeyedArchiver.archivedDataWithRootObject(dic)

            if data.writeToFile(path, atomically: true) == true {
                PrintLog("崩溃日志保存成功",level: .Debug)
            }else {
                PrintLog("崩溃日志保存失败",level: .Error)
            }
        }

    }
}