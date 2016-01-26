//
//  UBAUpload.swift
//  UBAAgent
//
//  Created by hwh on 16/1/24.
//  Copyright © 2016年 Huangwh. All rights reserved.
//

import UIKit

let instance = UBAUpload()
typealias CompleteHandle = (responseString: String?,status: Int, error: NSError?) -> Void
class UBAUpload: NSObject {
    let session = NSURLSession.sharedSession()
    
    class var ShareInstance: UBAUpload {
        return instance
    }
    func request(urlString: String? = nil, params: String ,complete:CompleteHandle) {
        var urlPath = urlString ?? "http://localhost/upload.php?"
        urlPath += "events=\(params)"
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet()
        let url = NSURL(string: urlPath.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "X-Accept")
        
        let task = session.dataTaskWithRequest(NSURLRequest(URL: url!)) { (data, response, error) -> Void in
            if data == nil {
                complete(responseString: nil, status: -1, error: nil)
                return
            }
            let responseString = String(data: data!, encoding: NSUTF8StringEncoding)
            complete(responseString: responseString, status: 0, error: nil)
        }
        task.resume()
    }
    func uploadAllEvents() {
        UBADB.GetEvents { (events, page,complete) -> () in
            PrintLog("发送第\(events.count)次")
            if complete || events.count <= 0{
                PrintLog("本地已经没有事件需要发送")
                return
            }
            var dics = [[String: AnyObject]]()
            for event in events {
                var dic = [String: AnyObject]()
                dic["identify"] = event.identify
                dic["eventId"]  = event._eventId
                dic["create_at"] = event.create_at
                dic["update_at"] = event.update_at
                dic["label"]     = event._label
                dics.append(dic)
            }
            var resultDic = [String: AnyObject]()
            resultDic["root"] = dics
            let dictionary = resultDic as NSDictionary
            do {
                let uploadJson = try NSJSONSerialization.dataWithJSONObject(dictionary, options: .PrettyPrinted)
                let uploadString = String(data: uploadJson, encoding: NSUTF8StringEncoding)
                instance.request(params: uploadString!, complete: {[unowned self] (responseString, status, error) -> Void in
                    if responseString != nil  && error == nil{
                        let data = responseString!.dataUsingEncoding(NSUTF8StringEncoding)
                        let object = try! NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        PrintLog("返回结果:\n \(object)")
                    }

                    self.next()
                })
            }catch {
                PrintLog("\(error)")
            }
            
            
        }
    }
    func next() {
        UBADB.Next()
    }
}
