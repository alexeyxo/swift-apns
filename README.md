#Simple framework for sending Apple Push Notifications
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
####Required Protocol Buffers 3.0 and [protobuf-swift](https://github.com/alexeyxo/protobuf-swift)

##<img src="https://cloud.githubusercontent.com/assets/432536/5252404/443d64f4-7952-11e4-9d26-fc5cc664cb61.png" width="22" height="22"> Installation via [Carthage](https://github.com/Carthage/Carthage)
```Cartfile
github "alexeyxo/protobuf-swift" "ProtoBuf3.0-Swift2.0"
github "alexeyxo/swift-apns"

```

###Example
```swift
let providerData = Apple.Apns.ProviderData.Builder()
providerData.bundle = "com.mytestapp.test"
providerData.serviceIdentity = Apple.Apns.ProviderData.Identity.Development
providerData.priority = 10
providerData.certificateName = "push" //push.p12
providerData.certificatePassphrase = "123456"
providerData.token = "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe"

let aps = Apple.Apns.Push.Aps.Builder()
aps.badge = 1
aps.contentAvailable = 1
aps.sound = "default"
aps.alert = "test"
do {
    let payload = try Apple.Apns.Push.Builder().setAps(aps.build()).build()
    providerData.payload = payload
    try Apple.Apns.Network().sendPush(providerData.build(), responseBlock: { (response) -> () in
        print(response)
    })
} catch {
    
}
```

###Sending custom objects

Edit ./Source/ProtoSource/PushService.proto

```protobuf
...
message Push {
    message Aps {
        string alert = 1;
        string sound = 2;
        int32 badge = 3;
        int32 content_available = 4;
        string category = 5; 
    }
    
    message ExampleCustomObject {
        string objectId = 1;
    }
    
	Aps aps = 1;
    ExampleCustomObject customObject = 2;
}
```

Compile new object:
```protoc PushService.proto --swift_out="../"```