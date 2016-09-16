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
    
    public static func getServiceReasonBy(str:String) -> (APNServiceErrorReason, String) {
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

public enum APNServiceStatus: Error {
    case success
    case badRequest
    case badCertitficate
    case badMethod
    case deviceTokenIsNoLongerActive
    case badNotificationPayload
    case serverReceivedTooManyRequests
    case internalServerError
    case serverShutingDownOrUnavailable
    
    public static func statusCodeFrom(response:HTTPURLResponse) -> (Int, APNServiceStatus) {
        switch response.statusCode {
        case 400:
            return (response.statusCode,APNServiceStatus.badRequest)
        case 403:
            return (response.statusCode,APNServiceStatus.badCertitficate)
        case 405:
            return (response.statusCode,APNServiceStatus.badMethod)
        case 410:
            return (response.statusCode,APNServiceStatus.deviceTokenIsNoLongerActive)
        case 413:
            return (response.statusCode,APNServiceStatus.badNotificationPayload)
        case 429:
            return (response.statusCode,APNServiceStatus.serverReceivedTooManyRequests)
        case 500:
            return (response.statusCode,APNServiceStatus.internalServerError)
        case 503:
            return (response.statusCode,APNServiceStatus.serverShutingDownOrUnavailable)
        default: return (response.statusCode,APNServiceStatus.success)
        }
    }
}

/// Apple Push Notification Message
public struct ApplePushMessage {
    /// Message Id
    fileprivate(set) public var messageId:String = UUID().uuidString
    /// Application BundleID
    public var topic:String
    /// APNS Priority 5 or 10
    public var priority:Int
    /// APNS Payload aps {...}
    public var payload:Dictionary<String,AnyObject>
    /// Device Token without <> and whitespaces
    public var deviceToken:String
    /// Path for P12 certificate
    public var certificatePath:String
    /// Passphrase for certificate
    public var passphrase:String
    /// Use sandbox server URL or not
    public var sandbox:Bool
    /// Response Clousure
    public var responseBlock:((APNServiceResponse) -> ())?
    /// Network error Clousure
    public var networkError:((Error?)->())?
    /// Custom UrlSession
    public var session:URLSession?
    /// Send current message
    ///
    /// - throws: Method can throw error if payload data isn't parse.
    ///
    /// - returns: URLSessionDataTask
    public func send() throws -> URLSessionDataTask? {
        return try APNSNetwork(session:session).sendPushWith(message: self)
    }
    /// Send current message with custom URLSession
    ///
    /// - parameter session: URLSession
    ///
    /// - throws: Method can throw error if payload data isn't parse.
    ///
    /// - returns: URLSessionDataTask
    public func sendWith(session:URLSession?) throws -> URLSessionDataTask? {
        return try APNSNetwork(session:session).sendPushWith(message: self)
    }
}


open class APNSNetwork:NSObject {
    fileprivate var secIdentity:SecIdentity?
    static fileprivate var session:URLSession?
    public convenience override init() {
        self.init(session:nil)
    }
    
    public init(session:URLSession?) {
        super.init()
        guard let session = session else {
            APNSNetwork.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
            return
        }
        APNSNetwork.session = session
    }

    
    open func sendPushWith(message:ApplePushMessage) throws -> URLSessionDataTask?  {
        return try sendPushWith(topic: message.topic,
                                priority: message.priority,
                                payload: message.payload,
                                deviceToken: message.deviceToken,
                                certificatePath: message.certificatePath,
                                passphrase: message.passphrase,
                                sandbox: message.sandbox,
                                responseBlock: message.responseBlock,
                                networkError: message.networkError)
    }
    
    internal func sendPushWith(topic:String, priority:Int, payload:Dictionary<String,Any>, deviceToken:String, certificatePath:String, passphrase:String, sandbox:Bool, responseBlock:((APNServiceResponse) -> ())?, networkError:((Error?)->())?) throws -> URLSessionDataTask? {
        
        let url = serviceURLFor(sandbox: sandbox, token: deviceToken)
        var request = URLRequest(url: url)
        
        guard let ind = getIdentityWith(certificatePath: certificatePath, passphrase: passphrase) else {
            return nil
        }
        self.secIdentity = ind
        
        let data = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions(rawValue: 0))
        request.httpBody = data
        request.httpMethod = "POST"
        request.addValue(topic, forHTTPHeaderField: "apns-topic")
        request.addValue("\(priority)", forHTTPHeaderField: "apns-priority")
        
        let task = APNSNetwork.session?.dataTask(with: request, completionHandler:{ (data, response, err) -> Void in
            
            guard err == nil else {
                networkError?(err)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                networkError?(err)
                return
            }
            
            let (statusCode, status) = APNServiceStatus.statusCodeFrom(response: response)
            let httpResponse = response
            let apnsId = httpResponse.allHeaderFields["apns-id"] as? String
            var responseStatus = APNServiceResponse(serviceStatus: (statusCode, status), serviceErrorReason: nil, apnsId: apnsId)
            
            guard status == .success else {
                let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0))
                guard let js = json as? Dictionary<String,Any>,
                    let reason = js["reason"] as? String
                    else {
                        return
                    }
                let serviceReason = APNServiceErrorReason(rawValue: reason)
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

extension APNSNetwork: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var cert : SecCertificate?
        SecIdentityCopyCertificate(self.secIdentity!, &cert)
        let credentials = URLCredential(identity: self.secIdentity!, certificates: [cert!], persistence: .forSession)
        completionHandler(.useCredential,credentials)
    }
}

extension APNSNetwork {
    internal func getIdentityWith(certificatePath:String, passphrase:String) -> SecIdentity? {
        let PKCS12Data = try? Data(contentsOf: URL(fileURLWithPath: certificatePath))
        let key : String = kSecImportExportPassphrase as String
        let options = [key : passphrase]
        var items : CFArray?
        let ossStatus = SecPKCS12Import(PKCS12Data! as CFData, options as CFDictionary, &items)
        guard ossStatus == errSecSuccess else {
            return nil
        }
        let arr = items!
        if CFArrayGetCount(arr) > 0 {
            let newArray = arr as [AnyObject]
            let dictionary = newArray[0]
            let secIdentity = dictionary.value(forKey: kSecImportItemIdentity as String) as! SecIdentity
            return secIdentity
        }
        return nil
    }
    
    fileprivate func serviceURLFor(sandbox:Bool, token:String) -> URL {
        var serviceStrUrl:String?
        switch sandbox {
        case true: serviceStrUrl = "https://api.development.push.apple.com:443/3/device/"
        case false: serviceStrUrl = "https://api.push.apple.com:443/3/device/"
        }
        return URL(string: serviceStrUrl! + token)!
    }
}



