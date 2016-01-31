//
//  APNS-Protobuf.swift
//  APNS
//
//  Created by Alexey Khokhlov on 30.01.16.
//  Copyright © 2016 Alexey Khokhlov. All rights reserved.
//

import Foundation

extension APNSNetwork {
    
    public func sendPush(pushService:Apple.Apns.ProviderData, responseBlock:((response:Apple.Apns.Response) -> Void)?) throws -> NSURLSessionDataTask? {
        
        let payload = try getPayload(pushService)
        var sandbox = true
        if pushService.serviceIdentity == .Production {
            sandbox = false
        }
        let task =  try sendPush(pushService.bundle, priority: Int(pushService.priority), payload: payload, deviceToken: pushService.token, certificatePath: pushService.certificatePath, passphrase: pushService.certificatePassphrase, sandbox: sandbox) { (response) -> Void in
            let responseObject = APNServiceStatus.getResponseObject(response)
            responseBlock?(response: responseObject)
        }
        return task
        
    }
    
    private func getIdentityWith(providerData:Apple.Apns.ProviderData) -> SecIdentityRef? {
        return getIdentityWith(providerData.certificatePath, passphrase: providerData.certificatePassphrase)
    }
    
    private func getPayload(push:Apple.Apns.ProviderData) throws -> Dictionary<String,AnyObject> {
        var payload = try push.payload.encode()
        if var aps = payload["aps"] as? Dictionary<String,AnyObject> {
            if let contentAvailable = aps["contentAvailable"] {
                aps["content-available"] = contentAvailable
                aps.removeValueForKey("contentAvailable")
                payload["aps"] = aps
                
            }
        }
        return payload
    }
    
    
}

extension APNServiceStatus {
    public static func getResponseObject(response:APNServiceResponse) -> Apple.Apns.Response {
        let builder = Apple.Apns.Response.Builder()
        builder.statusCode = Int32(response.serviceStatus.0)
        if let reason = response.serviceErrorReason {
            builder.reason = reason.rawValue
            builder.reasonDescription = reason.getReasonDescription()
        }
        if let apnsId = response.apnsId {
            builder.apnsId = apnsId
        }
        return try! builder.build()
    }
}