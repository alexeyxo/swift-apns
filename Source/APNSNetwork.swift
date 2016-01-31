//
//  APNSNetwork.swift
//  APNS
//
//  Created by Alexey Khokhlov on 25.01.16.
//  Copyright © 2016 Alexey Khokhlov. All rights reserved.
//

import Foundation
import Security


public enum APNServiceErrorReason:String,CustomStringConvertible {
    case PayloadEmpty = "PayloadEmpty"
    case PayloadTooLarge = "PayloadTooLarge"
    case BadTopic = "BadTopic"
    case TopicDisallowed = "TopicDisallowed"
    case BadMessageId = "BadMessageId"
    case BadExpirationDate = "BadExpirationDate"
    case BadPriority = "BadPriority"
    case MissingDeviceToken = "MissingDeviceToken"
    case BadDeviceToken = "BadDeviceToken"
    case DeviceTokenNotForTopic = "DeviceTokenNotForTopic"
    case Unregistered = "Unregistered"
    case DuplicateHeaders = "DuplicateHeaders"
    case BadCertificateEnvironment = "BadCertificateEnvironment"
    case BadCertificate = "BadCertificate"
    case Forbidden = "Forbidden"
    case BadPath = "BadPath"
    case MethodNotAllowed = "MethodNotAllowed"
    case TooManyRequests = "TooManyRequests"
    case IdleTimeout = "IdleTimeout"
    case Shutdown = "Shutdown"
    case InternalServerError = "InternalServerError"
    case ServiceUnavailable = "ServiceUnavailable"
    case MissingTopic = "MissingTopic"
    
    public func getReasonDescription() -> String {
        switch self {
        case .PayloadEmpty: return "The message payload was empty."
        case .PayloadTooLarge: return "The message payload was too large. The maximum payload size is 4096 bytes."
        case .BadTopic: return "The apns-topic was invalid."
        case .TopicDisallowed: return "Pushing to this topic is not allowed."
        case .BadMessageId: return "The apns-id value is bad."
        case .BadExpirationDate: return "The apns-expiration value is bad."
        case .BadPriority: return "The apns-priority value is bad."
        case .MissingDeviceToken: return "The device token is not specified in the request :path. Verify that the :path header contains the device token."
        case .BadDeviceToken: return "The specified device token was bad. Verify that the request contains a valid token and that the token matches the environment."
        case .DeviceTokenNotForTopic: return "The device token does not match the specified topic."
        case .Unregistered: return "The device token is inactive for the specified topic."
        case .DuplicateHeaders: return "One or more headers were repeated."
        case .BadCertificateEnvironment: return "The client certificate was for the wrong environment."
        case .BadCertificate: return "The certificate was bad."
        case .Forbidden: return "The specified action is not allowed."
        case .BadPath: return "The request contained a bad :path value."
        case .MethodNotAllowed: return "The specified :method was not POST."
        case .TooManyRequests: return "Too many requests were made consecutively to the same device token."
        case .IdleTimeout: return "Idle time out."
        case .Shutdown: return "The server is shutting down."
        case .InternalServerError: return "An internal server error occurred."
        case .ServiceUnavailable: return "The service is unavailable."
        case .MissingTopic: return "The apns-topic header of the request was not specified and was required. The apns-topic header is mandatory when the client is connected using a certificate that supports multiple topics."
        }
    }
    
    public static func getServiceReasonByString(str:String) -> (APNServiceErrorReason, String) {
        let reason = APNServiceErrorReason(rawValue: str)!
        return (reason, reason.getReasonDescription())
    }
    
    public var description: String {
        return self.rawValue + ": " + getReasonDescription()
    }
}

public struct APNServiceResponse {
    public var serviceStatus:(Int, APNServiceStatus)
    public var serviceErrorReason:APNServiceErrorReason?
    public var apnsId:String?
}

public enum APNServiceStatus: ErrorType {
    case Success
    case BadRequest
    case BadCertitficate
    case BadMethod
    case DeviceTokenIsNoLongerActive
    case BadNotificationPayload
    case ServerReceivedTooManyRequests
    case InternalServerError
    case ServerShutingDownOrUnavailable
    
    public static func checkStatusCode(response:NSHTTPURLResponse) -> (Int, APNServiceStatus) {
        switch response.statusCode {
        case 400:
            return (response.statusCode,APNServiceStatus.BadRequest)
        case 403:
            return (response.statusCode,APNServiceStatus.BadCertitficate)
        case 405:
            return (response.statusCode,APNServiceStatus.BadMethod)
        case 410:
            return (response.statusCode,APNServiceStatus.DeviceTokenIsNoLongerActive)
        case 413:
            return (response.statusCode,APNServiceStatus.BadNotificationPayload)
        case 429:
            return (response.statusCode,APNServiceStatus.ServerReceivedTooManyRequests)
        case 500:
            return (response.statusCode,APNServiceStatus.InternalServerError)
        case 503:
            return (response.statusCode,APNServiceStatus.ServerShutingDownOrUnavailable)
        default: return (response.statusCode,APNServiceStatus.Success)
        }
    }
}

public class APNSNetwork:NSObject {
    private var secIdentity:SecIdentityRef?
    private var session:NSURLSession?
    public override init() {
        super.init()
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    internal func getIdentityWith(certificatePath:String, passphrase:String) -> SecIdentityRef? {
        let PKCS12Data = NSData(contentsOfFile: certificatePath)
        let key : String = kSecImportExportPassphrase as String
        let options = [key : passphrase]
        var items : CFArray?
        let ossStatus = SecPKCS12Import(PKCS12Data!, options, &items)
        guard ossStatus == errSecSuccess else {
            return nil
        }
        let arr = items!
        if CFArrayGetCount(arr) > 0 {
            let newArray = arr as [AnyObject]
            let dictionary = newArray[0]
            let secIdentity = dictionary.valueForKey(kSecImportItemIdentity as String) as! SecIdentityRef
            return secIdentity
        }
        return nil
    }
    private func getServiceURL(sandbox:Bool, token:String) -> NSURL {
        var serviceStrUrl:String?
        switch sandbox {
        case true: serviceStrUrl = "https://api.development.push.apple.com:443/3/device/"
        case false: serviceStrUrl = "https://api.push.apple.com:443/3/device/"
        }
        return NSURL(string: serviceStrUrl! + token)!
    }
    
    public func sendPush(topic:String, priority:Int, payload:Dictionary<String,AnyObject>, deviceToken:String, certificatePath:String, passphrase:String, sandbox:Bool, responseBlock:((APNServiceResponse) -> Void)?) throws -> NSURLSessionDataTask? {
        
        let url = getServiceURL(sandbox, token: deviceToken)
        let request = NSMutableURLRequest(URL: url)
        
        guard let ind = getIdentityWith(certificatePath, passphrase: passphrase) else {
            return nil
        }
        self.secIdentity = ind
        
        let data = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions(rawValue: 0))
        request.HTTPBody = data
        request.HTTPMethod = "POST"
        request.addValue(topic, forHTTPHeaderField: "apns-topic")
        request.addValue("\(priority)", forHTTPHeaderField: "apns-priority")
        
        let task = self.session?.dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
           
            let (statusCode, status) = APNServiceStatus.checkStatusCode((response as! NSHTTPURLResponse))
            let httpResponse = (response as! NSHTTPURLResponse)
            let apnsId = httpResponse.allHeaderFields["apns-id"] as? String
            var responseStatus = APNServiceResponse(serviceStatus: (statusCode, status), serviceErrorReason: nil, apnsId: apnsId)
            
            guard status == .Success else {
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0))
                let serviceReason = APNServiceErrorReason(rawValue: (json["reason"] as! String))
                responseStatus.serviceErrorReason = serviceReason
                responseBlock?(responseStatus)
                return
            }
            responseStatus.apnsId = apnsId
            responseBlock?(responseStatus)
        })
        task?.resume()
        return task
        
    }
}

extension APNSNetwork:NSURLSessionDelegate {
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        var cert : SecCertificate?
        SecIdentityCopyCertificate(self.secIdentity!, &cert)
        let credentials = NSURLCredential(identity: self.secIdentity!, certificates: [cert!], persistence: .ForSession)
        completionHandler(.UseCredential,credentials)
    }
}



