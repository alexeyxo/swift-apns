<p align="center">
  <a href="">
    <img alt="Logo" src="logo.png" width="600px">
  </a>

   Simple framework for sending Apple Push Notifications.

  <a href="https://github.com/Carthage/Carthage"><img alt="Carthage compatible" src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>

  <a href="http://cocoapods.org/?q=APNS"><img alt="Version" src="http://img.shields.io/cocoapods/v/APNS.svg"></a>

  <a href="http://cocoapods.org/?q=APNS"><img alt="Platform" src="http://img.shields.io/cocoapods/p/APNS.svg"></a>

</p>

## Installation

### <img src="https://avatars3.githubusercontent.com/u/1189714" width="22" height="22"> CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate *swift-apns* into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'APNS', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### <img src="https://cloud.githubusercontent.com/assets/432536/5252404/443d64f4-7952-11e4-9d26-fc5cc664cb61.png" width="22" height="22"> Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew install carthage
```

To integrate *swift-apns* into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "alexeyxo/swift-apns"
```

Run `carthage update` to build the framework and drag the built `.framework` file into your Xcode project.


## Usage

### Simple Example

```swift
let aps = ["sound":"default", "alert":"testPush()"]
let payload = ["aps":aps]
try! APNSNetwork().sendPush("com.myapp.bundle",
        priority: 10,
        payload: payload,
        deviceToken: "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe",
        certificatePath: NSBundle.mainBundle().pathForResource("push", ofType: "p12")!,
        passphrase: "123456",
        sandbox: true) { (response) -> Void in

        }
```

### Using with "Protocol Buffers"

> Required Protocol Buffers 3.0 and [protobuf-swift](https://github.com/alexeyxo/protobuf-swift)

#### Simple Example
```swift
let providerData = Apple.Apns.ProviderData.Builder()
providerData.bundle = "com.advisa.voipservice"
providerData.serviceIdentity = Apple.Apns.ProviderData.Identity.Development
providerData.priority = 10
providerData.certificatePath = NSBundle(forClass:UnitTest.self).pathForResource("push", ofType: "p12")!
providerData.certificatePassphrase = "123456"
providerData.token = "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe"

let aps = Apple.Apns.Push.Aps.Builder()
aps.badge = 1
aps.contentAvailable = 1
aps.sound = "default"
aps.alert = "testSendProtobuf()"
do {
    let payload = try Apple.Apns.Push.Builder().setAps(aps.build()).build()
    providerData.payload = payload
    try APNSNetwork().sendPush(providerData.build(), responseBlock: { (response) -> () in
        print(response)
    })
} catch {

}
```

#### Sending custom objects

1. Edit ./Source/ProtoSource/PushService.proto:
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

2. Compile new object:
  ```bash
  protoc PushService.proto --swift_out="../"
  ```
