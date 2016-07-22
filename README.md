<p align="center">
  <a href="">
    <img alt="Logo" src="https://raw.githubusercontent.com/alexeyxo/swift-apns/master/logo.png" width="500px">
  </a>
</p>

<p align="center">
   Simple framework for sending Apple Push Notifications.
</p>

<p align="center">

  <a href="https://github.com/Carthage/Carthage"><img alt="Carthage compatible" src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>

  <a href="http://cocoapods.org/?q=APNS"><img alt="Version" src="http://img.shields.io/cocoapods/v/APNS.svg"></a>

  <a href="http://cocoapods.org/?q=APNS"><img alt="Platform" src="http://img.shields.io/cocoapods/p/APNS.svg"></a>

</p>

## Table of Contents

- [Installation](#installation)
  - [CocoaPods](#-cocoapods)
  - [Carthage](#-carthage)
- [Usage](#usage)
  - [Simple Example](#simple-example)
  - [Using with "Protocol Buffers"](#using-with-protocol-buffers)
    - [Simple Example](#simple-example-1)
    - [Sending Custom Objects](#sending-custom-objects)
- [Credits](#credits)

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
_ = try! APNSNetwork().sendPush(topic: "com.asdasd.asdasdas", priority: 10, payload: payload, deviceToken: "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe", certificatePath: Bundle(for:UnitTest.self).pathForResource("push", ofType: "p12")!, passphrase: "123456", sandbox: true, responseBlock: { (response) in
        XCTAssertTrue(response.serviceStatus.0 == 200)
        self.expectation.fulfill()
    }, networkError: { (error) in
        
})
```

```swift
        
        let aps = ["sound":"default", "alert":"testPush()"]
        let payload = ["aps":aps]
        let str = Bundle(for:UnitTest.self).pathForResource("cert", ofType: "p12")!
        var mess = ApplePushMessage(topic: "com.tests.asdasdasd",
                             priority: 10,
                             payload: payload,
                             deviceToken: "3dd55a59056441ab275b8b679458388cae76be3a9a02a00234388e50fe91f2fe",
                             certificatePath:str,
                             passphrase: "123456",
                             sandbox: true,
                             responseBlock:nil,
                             networkError:nil, session: nil)
        
        mess.responseBlock = { response in
        }
        
        mess.networkError = { err in
            if (err != nil) {

            }
        }
        _ = try! mess.send() // OR try! mess.send(session:<URLSession>) 
        

```

### Using with "Protocol Buffers"

> Required Protocol Buffers 3.0 and [protobuf-swift](https://github.com/alexeyxo/protobuf-swift).

#### Simple Example
```swift
let providerData = Apple.Apns.ProviderData.Builder()
providerData.bundle = "com.aasdad.asdasdsdfa"
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

#### Sending Custom Objects

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

## Credits

- The bird used in the logo - as well as the cloud - are borrowed respectively
from the original *Swift* and *APNs* logos which have
*All Rights Reserved to Apple Inc.

- The font used in logo comes from the [San Francisco family](https://developer.apple.com/fonts/).
