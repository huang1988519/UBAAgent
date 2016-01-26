//
//  UBAAgent.swift
//  UBAAgent
//
//  Created by hwh on 16/1/22.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import Foundation
import CryptoSwift

private let shareAgentInstance = UBAAgent()
private let ReStartUBATimerInterval = 10 * 3600  //如果程序进入后台 10分钟，就相当于程序杀掉重新加进入

public class UBAAgent : NSObject {

    /// set  send log to service timer interval ,default is 30s
    private var _logSendInterval: NSTimeInterval = 30
    private var _appId: String = ""
    private var _reportPolicy: UBAReportPolicy = .BATCH
    
    private var _startStamp: NSTimeInterval = 0 //程序启动时间
    private var _enterToBackGoundStamp: NSTimeInterval = 0  // 程序进入后台的时间
    //标识符
    private var _identify   : String = ""
    private var _maxUploadLimitCount = 1 //1 ，方便测试
    
    private var _exception: UBAException?
    private var _signal   : UBASignal?
    
    private var _appBackTask:UIBackgroundTaskIdentifier? = 0
    public enum UBAReportPolicy: Int {
        case RealTime    //实时上传
        case BATCH       //程序启动时 批量处理
    }
    /// 访问单例 private
    class var ShareInstance: UBAAgent {
//        performSelector("hehe", withObject: nil, afterDelay: 5)
//        performSelector("haha",withObject:  nil, afterDelay: 3)
        return shareAgentInstance
    }
    override init() {
    }
    
    //MARK: - Public Class Methed
    /**
    统计初始化
    
    - parameter appId:        统计应用，分配的appId
    - parameter reportPolicy: 日志上传 方式  [批量|实时] ,default .BATCH
    */
    public class func StartWithAppId(appId: String, reportPolicy: UBAReportPolicy ) {
        ShareInstance.initWithAppId(appId, reportPolicy: reportPolicy)
    }
    public class func PostEvent(eventID: String, label: String? = nil) {
        let event = Event(id: eventID,label: label)
        UBADB.InsertEvent(event)
    }
    public class func Identify() -> String {
        return ShareInstance._identify
    }
    public class func EnableCrashReport() {
        ShareInstance._exception = UBAException()
        ShareInstance._exception?.EnableException()
        
        ShareInstance._signal = UBASignal()
        ShareInstance._signal?.EnableSignal()
    }
    /**
    单次上传最多条数据 限制 ,默认 100
    
    - parameter limit: 上传上限
    */
    public class func maxUploadlimit(limit: NSInteger) {
        assert(limit>=1, "限制必须大于0")
        ShareInstance._maxUploadLimitCount = limit
    }
    /**
     设置 用户统计是否打印Log
     
     - parameter enable: 是否打开日志系统 (default is True)
     */
    public class func setLogEnable(enable: Bool) {
        NSLog("[UBA]打开控制台输出")
        
        userdefault.setBool(enable, forKey: Constant.UserDefaultKey.enableLogKey)
        userdefault.synchronize()
        
        UBAUpload.ShareInstance.uploadAllEvents()
    }
    /**
      set  send log to service timer interval ,default is 30s
     
     - parameter timerInterval: send log timer interval
     */
    public class func setLogSendInterval(timerInterval: NSTimeInterval) {
        UBAAgent.ShareInstance._logSendInterval = timerInterval
    }
    
    
    //MARK: - Instance Methed
    func initWithAppId(appId: String, reportPolicy: UBAReportPolicy) {
        PrintLog("统计程序启动")
        _appId = appId
        _reportPolicy = reportPolicy
        
        _startStamp    = NSDate.currentDateStamp()
        _identify      = Helper.IdentifyForStamp(_startStamp)
        //注册通知
       registestNotification()
        
        self.performSelectorInBackground("postEventsToService", withObject: nil)
    }
    func registestNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "becomeActive:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        
        
    }
    func becomeActive(notification: NSNotification) {
        PrintLog("程序进入前台")
        let app = UIApplication.sharedApplication()
        app.endBackgroundTask(_appBackTask!)
    }
    func resignActive(notifcation: NSNotification) {
        PrintLog("程序进入后台")
        _enterToBackGoundStamp = NSDate.currentDateStamp()
        
        //Debug 时不放到后台执行
        UBADB.BackUpTempDB()
        return;
        
        let app = UIApplication.sharedApplication()
        _appBackTask = app.beginBackgroundTaskWithExpirationHandler({ () -> Void in
            UBADB.BackUpTempDB()
        })
    }
    /**
     给服务器发送 事件
     */
    func postEventsToService() {
        if _reportPolicy == .BATCH {
            postAllEvents()
        }else {
            postEventsAtPeriod()
        }
    }
    /**
     发送所有事件
     */
    func postAllEvents() {
        PrintLog("发送所有事件")
        dispatch_async { () -> Void in
        }
    }
    /**
     定时发送事件
     */
    func postEventsAtPeriod() {
        PrintLog("定时发送事件")
    }
    
}


