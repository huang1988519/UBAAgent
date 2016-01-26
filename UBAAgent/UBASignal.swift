//
//  UBASignal.swift
//  UBAAgent
//
//  Created by hwh on 16/1/25.
//  Copyright © 2016年 Huangwh. All rights reserved.
//
//
//*
//*                            ___====-_  _-====___
//*                      _--^^^#####//      \\#####^^^--_
//*                   _-^##########// (    ) \\##########^-_
//*                  -############//  |\^^/|  \\############-
//*                _/############//   (@::@)   \\############\_
//*               /#############((     \\//     ))#############\
//*              -###############\\    (oo)    //###############-
//*             -#################\\  / VV \  //#################-
//*            -###################\\/      \//###################-
//*           _#/|##########/\######(   /\   )######/\##########|\#_
//*           |/ |#/\#/\#/\/  \#/\##\  |  |  /##/\#/  \/\#/\#/\#| \|
//*           `  |/  V  V  `   V  \#\| |  | |/#/  V   '  V  V  \|  '
//*              `   `  `      `   / | |  | | \   '      '  '   '
//*                               (  | |  | |  )
//*                              __\ | |  | | /__
//*                             (vvv(VVV)(VVV)vvv)

import Foundation
import SystemConfiguration
class Test {
    var mySig: sigaction = sigaction()
    init() {
        print("\(__FUNCTION__)")
        mySig.sa_flags = SA_SIGINFO
        mySig.__sigaction_u = __sigaction_u(__sa_handler: { (sig_t) -> Void in
            print(123)
        })
        sigemptyset(&mySig.sa_mask)
        sigaction(SIGHUP, &mySig, nil)
        sigaction(SIGINT, &mySig, nil)
        sigaction(SIGQUIT, &mySig, nil)
        sigaction(SIGABRT, &mySig, nil)
        sigaction(SIGILL, &mySig, nil)
        sigaction(SIGFPE, &mySig, nil)
        sigaction(SIGSEGV, &mySig, nil)
        sigaction(SIGBUS, &mySig, nil)
        sigaction(SIGPIPE, &mySig, nil)
        
        sigaction(SIGTRAP, &mySig, nil)
        sigaction(SIGEMT, &mySig, nil)
        sigaction(SIGFPE, &mySig, nil)
        sigaction(SIGSYS, &mySig, nil)
        
        sigaction(SIGALRM, &mySig, nil)
        sigaction(SIGXCPU, &mySig, nil)
        sigaction(SIGXFSZ, &mySig, nil)
        
    }
    deinit {
        print("\(__FUNCTION__)")
    }
}
struct UBASignal {
    var mySig: sigaction = sigaction()
    
    static let RecieveSignal : @convention(c) (Int32) -> Void = {
        (signal) -> Void in
        PrintLog("收到 unix signal \(signal)\n 收集错误信息 --->")
        PrintLog("\(NSThread.currentThread().threadDictionary)")
        PrintLog("结束 unix signal \(signal)\n 收集错误信息 <---")
    }
    func EnableSignal() {
        let recieveSignal = UBASignal.RecieveSignal
        //用户终端连接(正常或非正常)结束时发出
        signal(SIGHUP, UBASignal.RecieveSignal)
        
        //程序终止(interrupt)信号, 在用户键入INTR字符(通常是Ctrl-C)时发出
        signal(SIGINT, recieveSignal)
        //和SIGINT类似, 但由QUIT字符(通常是Ctrl-)来控制. 进程在因收到SIGQUIT退出时会产生core文件, 在这个意义上类似于一个程序错误信号。
        signal(SIGQUIT, recieveSignal)
        signal(SIGABRT, recieveSignal)
        signal(SIGILL,  recieveSignal)
        signal(SIGSEGV, recieveSignal)
        signal(SIGFPE,  recieveSignal)
        signal(SIGBUS,  recieveSignal)
        signal(SIGPIPE, recieveSignal)
    }
    init() {
    }
    
}
