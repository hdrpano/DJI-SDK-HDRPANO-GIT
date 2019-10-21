![swift 5.0](https://img.shields.io/badge/swift-5.0-green.svg) ![platform iOS](https://img.shields.io/badge/platform-iOS-lightgrey.svg) ![pod 1.1.5](https://img.shields.io/badge/pod-1.1.1-blue.svg) ![DJI SDK 4.11](https://img.shields.io/badge/DJI%20SDK-4.11-blue.svg) ![DJI DUX SDK 4.11](https://img.shields.io/badge/DJI%20DUX%20SDK-4.11-blue.svg) ![license MIT](https://img.shields.io/badge/license-MIT-green.svg) ![Aircrafts](https://img.shields.io/badge/Aircrafts-Inspire%20%7C%20Matrice%20%7C%20Mavic%20%7C%20Phantom%20%7C%20Spark-lightgrey.svg)

# EASY DJI SDK with the Hdrpano Framework

## What is this?
This SDK is based on DJI iOS SDK's 
DJI-SDK-iOS 
DJI-UXSDK-iOS 
DJIWidget 

The Hdrpano Framework makes it easy to code new APP's. You can build your onw APP in a few minutes. Wath the tutorial on my YouTube channel. 

This project uses Swift 5.0

This SDK simplify the use of keys and functions. For example:

    Hdrpano.setMaxHeight(Height: 120)           // Set max flight height EASA, Skyguide rules
    Hdrpano.setMaxRadius(Radius: 500)           // Set max distance to EASA, Skyguid rules
    Hdrpano.setLowBattery(Low: 30)              // Set low battery to 30%
    Hdrpano.setFileFormat(fileFormat: .JPEG)    // Set file format
    Hdrpano.setShootMode(shootMode: .single)    // Set shooting mode
    Hdrpano.setISO(ISO: .ISO100)                // Set ISO to max resolution

Thanks to the autocompletion of Xcode you can see the right settings. Xcode gives you a choice for completion: If you type 

    Hdrpano.setISO(ISO: .
                        .AUTO 
                        .ISO100
                        .ISO200

You will see all logic possibilites

There are some powerfull functions in this SDK

    self.panoSettings = Hdrpano.getSettings(modelName: self.aircraftModel)

This function returns an array for your aircraft with the optimum settings for rows, columns, focal length, maximum pitch and minimum pitch. Do not change this values!
The maximum pitch angle for a mission and the Mavic 2 aircraft is +25°, not +30°. The mission code will not work if you change this value. DJI uses only +13° in their intern panorama function.

    let grid = Hdrpano.createGridLinear(cols: self.panoSettings[1], rows: self.panoSettings[0], 
               maxGimb: Float(self.panoSettings[3]), maxNadir: self.panoSettings[4])

This function returns an array of panorama positions for your aircraft. With this array it is easy to move the aicraft and the gimbal for a full size panorama.
This SDK creates a **Papywizard xml file** with this grid too. Yuu can save this file with airdrop. This Papywizard xml file is compatible with Autopano and PTGui.
Watch my [videos](https://www.youtube.com/c/KilianEisenegger) to see how you can capture 5 zenith shots with your aircraft.

    func xmlGenerateGeneric() -> String {
        // Creates a Papywizard xml file for stitching in Autopano and PTGui
        self.panoSettings = Hdrpano.getSettings(modelName: self.aircraftModel)
        let grid = Hdrpano.createGridLinear(cols: self.panoSettings[1], rows: self.panoSettings[0], 
                   maxGimb: Float(self.panoSettings[3]), maxNadir: self.panoSettings[4])
        NSLog("Grid settings for xml \(grid) \(grid.count)")
        var xml: String = ""
        xml += Hdrpano.xmlHeader(modelName: self.aircraftModel, panoSettings: self.panoSettings)
        xml += Hdrpano.createGenericXML(grid: grid, modelName: self.aircraftModel)
        xml += Hdrpano.xmlEnd(counter: grid.count, heading: 0, zenith: 5)
        return xml
    }

    let fileName = Hdrpano.saveGenericXmlFile(xml: self.xmlGenerateGeneric(), modelName: self.aircraftModel)
    self.airdropXML(fileName: fileName)

Aircrafts like the Phantom 4 Pro or the Mavic have a continous auto focus AFC. The AFC mode doesn't work if the camera points for example blue sky. The camera can not find a focal point on blue sky. The photo capturing will freeze.
I have added a function to reset AFC mode to simple auto exposure mode. This function checks if AFC is available. 

    Hdrpano.setFocusModeAuto()

[![Watch the video](https://img.youtube.com/vi/XwM7Vq1Erjc/maxresdefault.jpg)](https://youtu.be/XwM7Vq1Erjc)

## Installation
**1.** Install CocoaPods

Open Terminal and change to the download project's directory, enter the following command to install it:

    sudo gem install cocoapods

The process may take a long time, please wait. For further installation instructions, please check [this guide](https://guides.cocoapods.org/using/getting-started.html#getting-started).

**2.** Install UX SDK and DJIWidget with CocoaPods in the Project

Run the following command in the **DUX-iOS** paths:

    pod install

If you install it successfully, you should get the messages similar to the following:

    Analyzing dependencies
    Downloading dependencies
    Installing Hdrpano (1.1.0)
    Installing DJI-SDK-iOS (4.10)
    Installing DJI-UXSDK-iOS (4.10)
    Installing DJIWidget (1.5)
    Generating Pods project
    Integrating client project

    [!] Please close any current Xcode sessions and use `DUX-iOS.xcworkspace` for this project from now on.
    Pod installation complete! There is 1 dependency from the Podfile and 1 total pod
    installed.

**Note**: If you saw "Unable to satisfy the following requirements" issue during pod install, please run the following commands to update your pod repo and install the pod again:

    pod repo update
    pod install

You can now import the framework in your swift file.

    import UIKit
    import DJIUXSDK
    import DJISDK
    import Hdrpano

### DJIWidget Integration
Starting from DJI iOS SDK 4.7, DJI has replaced the **VideoPreviewer** with **DJIWidget** for video decoding. 

The DUX-iOS project uses a DefaultViewController from the DJIWidget framework. I have added additional widgets in the default view.

    Gimbal Status Bar 
    Yaw Status Bar
    Coordinates widget 
    Focal length widget 
    AE button

The AE button copies auto exposure settings like ISO, aperture, exposure and EV into manual settings. This is very important for the panorama shooting witch is done in manual mode. The function can be called with:

    Hdrpano.setAE2AM()

## DJI SDK updates
If you update the DJI SDK with pod install the Hdrpano framework will always use this latest version. The Hdrpano framework needs only an update if the DJI SDK add new functions. 

## Timeline mission
This framework starts with a timeline panorama project.
Each aircraft has different focal length and camera capabilities. This framework handle all lenses (exept X3). 
X5, X5S, X7... Zoom lenses are supported. 

## Online tracking
This framework is prepared for Airmap use. This means online telemetry. 

## DJI Development Workflow
From registering as a developer, to deploying an application, the following will take you through the full Mobile SDK Application development process:

- [Prerequisites](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-prerequisits.html)
- [Register as DJI Developer & Download SDK](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-register.html)
- [Integrate SDK into Application](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-integrate.html)
- [Run Application](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-run.html)
- [Testing, Profiling & Debugging](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-testing.html)
- [Deploy](https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-deploy.html)

## How to use
pod install 
that will do it!

If you will learn how to use it watch my channel on YouTube

## The team
This framework is supported from [hdrpano](http://hdrpano.ch/) only. You can find a lot of tutorials on my YouTube [channel](https://www.youtube.com/c/KilianEisenegger)
