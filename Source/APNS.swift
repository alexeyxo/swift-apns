//
//  swift-apns.swift
//  APNS
//
//  Created by Alexey Khokhlov on 25.01.16.
//  Copyright © 2016 Alexey Khokhlov. All rights reserved.
//

import Foundation
import Security

extension Apple.Apns {
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
        
        public func getDescriptionByReason() -> String {
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
        public static func getServiceReasonByString(str:String) -> (Apple.Apns.APNServiceErrorReason, String) {
            let reason = Apple.Apns.APNServiceErrorReason(rawValue: str)!
            return (reason, reason.getDescriptionByReason())
        }
        
        public var description: String {
            return self.rawValue + ": " + getDescriptionByReason()
        }
    }
    
    public enum APNServiceError: ErrorType {
        case Success
        case BadRequest
        case BadCertitficate
        case BadMethod
        case DeviceTokenIsNoLongerActive
        case BadNotificationPayload
        case ServerReceivedTooManyRequests
        case InternalServerError
        case ServerShutingDownOrUnavailable
        
        public static func checkStatusCode(response:NSHTTPURLResponse) -> (Int, Apple.Apns.APNServiceError) {
            switch response.statusCode {
            case 400:
                return (response.statusCode,APNServiceError.BadRequest)
            case 403:
                return (response.statusCode,APNServiceError.BadCertitficate)
            case 405:
                return (response.statusCode,APNServiceError.BadMethod)
            case 410:
                return (response.statusCode,APNServiceError.DeviceTokenIsNoLongerActive)
            case 413:
                return (response.statusCode,APNServiceError.BadNotificationPayload)
            case 429:
                return (response.statusCode,APNServiceError.ServerReceivedTooManyRequests)
            case 500:
                return (response.statusCode,APNServiceError.InternalServerError)
            case 503:
                return (response.statusCode,APNServiceError.ServerShutingDownOrUnavailable)
            default: return (response.statusCode,APNServiceError.Success)
            }
        }
        
        public static func getResponseObject(response:NSHTTPURLResponse, data:NSData?) -> Apple.Apns.Response {
            
            let (statusCode, serviceError) = checkStatusCode(response)
            
            guard serviceError == .Success else {
                var responseObject = Apple.Apns.Response.Builder()
                if let jData = data {
                    responseObject = try! Apple.Apns.Response.Builder.fromJSONToBuilder(jData)
                    let (_, description) = APNServiceErrorReason.getServiceReasonByString(responseObject.reason)
                    responseObject.reasonDescription = description
                }
                responseObject.statusCode = Int32(statusCode)
                return try! responseObject.build()
            }
            
            let builder = Apple.Apns.Response.Builder()
            builder.statusCode = Int32(statusCode)
            builder.apnsId = response.allHeaderFields["apns-id"] as! String
            return try! builder.build()
        }
        
    }
    
    public class Network:NSObject {
        private var secIdentity:SecIdentityRef?
        private var session:NSURLSession?
        public override init() {
            super.init()
            self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        }
        
        func sendPush(pushService:Apple.Apns.ProviderData, responseBlock:((response:Apple.Apns.Response) -> ())?) throws -> NSURLSessionDataTask? {
            let url = getServiceURL(pushService)
            let request = NSMutableURLRequest(URL: url)
            
            guard let ind = getIdentity(pushService) else {
                return nil
            }
            self.secIdentity = ind
            request.HTTPMethod = "POST"
            request.HTTPBody = try getPayload(pushService)
            request.addValue(pushService.bundle, forHTTPHeaderField: "apns-topic")
            request.addValue("\(pushService.priority)", forHTTPHeaderField: "apns-priority")
            
            let task = self.session?.dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
                
                let responseObject = Apple.Apns.APNServiceError.getResponseObject((response as! NSHTTPURLResponse), data: data)
                responseBlock?(response: responseObject)
            })
            task?.resume()
            return task
        }
        
        
        private func getIdentity(pushService:Apple.Apns.ProviderData) -> SecIdentityRef? {
            let path = NSBundle.mainBundle().pathForResource(pushService.certificateName, ofType: "p12")!
            let PKCS12Data = NSData(contentsOfFile: path)
            let key : String = kSecImportExportPassphrase as String
            let options = [key : pushService.certificatePassphrase]
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
        
        private func getPayload(push:Apple.Apns.ProviderData) throws -> NSData {
            var payload = try push.payload.encode()
            if var aps = payload["aps"] as? Dictionary<String,AnyObject> {
                if let contentAvailable = aps["contentAvailable"] {
                    aps["content-available"] = contentAvailable
                    aps.removeValueForKey("contentAvailable")
                    payload["aps"] = aps
                    
                }
            }
            let data = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions(rawValue: 0))
            return data
        }
        
        private func getServiceURL(pushService:Apple.Apns.ProviderData) -> NSURL {
            var serviceStrUrl:String?
            switch pushService.serviceIdentity {
            case .Development: serviceStrUrl = "https://api.development.push.apple.com:443/3/device/"
            case .Production: serviceStrUrl = "https://api.push.apple.com:443/3/device/"
            }
            return NSURL(string: serviceStrUrl! + pushService.token)!
        }
    }
}

extension Apple.Apns.Network:NSURLSessionDelegate {
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        var cert : SecCertificate?
        SecIdentityCopyCertificate(self.secIdentity!, &cert)
        let credentials = NSURLCredential(identity: self.secIdentity!, certificates: [cert!], persistence: .ForSession)
        completionHandler(.UseCredential,credentials)
    }
}


