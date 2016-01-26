//
//  Event.swift
//  UBAAgent
//
//  Created by hwh on 16/1/22.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import UIKit

enum EventType: String {
    case Unknown  = "Unknown"
    case StartUp  = "StartUp"
    case End      = "End"
    case Event    = "Event"
    case SysEvent = "SysEvent"
}
struct EventsColumnName {
    static let id = "id"
    static let eventId = "eventId"
    static let label   = "label"
    static let create_at = "create_at"
    static let update_at = "update_at"
    static let identify  = "identify"
    static let type      = "type"
}
class Event: NSObject {
    var identify: String = UBAAgent.Identify()
    private(set) var _eventId: String = "0"
    private(set) var _label: String = "0"
    var type: EventType = .Unknown
    var create_at: NSTimeInterval = NSDate.currentDateStamp()
    var update_at: NSTimeInterval = 0
    
    override init() {
        super.init()
    }
    init(id: String, label:String? = nil) {
        _eventId = id
        if label != nil && label?.isEmpty ==  false {
            _label = label!
        }
    }
}
