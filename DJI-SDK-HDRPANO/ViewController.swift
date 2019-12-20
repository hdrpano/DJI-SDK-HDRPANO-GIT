//
//  ViewController.swift
//  DJI-SDK-HDRPANO
//
//  Created by Kilian Eisenegger on 07.08.19.
//  Copyright © 2019 Kilian Eisenegger. All rights reserved.
//

import UIKit
import DJISDK
import DJIUXSDK
import Hdrpano

class ViewController: DUXDefaultLayoutViewController {
    @IBOutlet weak var missionStart: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.contentViewController?.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.contentViewController?.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        self.contentViewController?.view.setNeedsDisplay()
        
        self.addKeyListener()
    }
    
    @IBAction func missionStartAction(_ sender: Any) {
        if let isRunning = DJISDKManager.missionControl()?.isTimelineRunning, isRunning == false {
            Hdrpano.startAdvancedVirtualStick()
            self.shootTLPano()
        } else {
            if let isPaused = DJISDKManager.missionControl()?.isTimelinePaused, isPaused == false {
                DJISDKManager.missionControl()?.pauseTimeline()
            } else {
                DJISDKManager.missionControl()?.resumeTimeline()
            }
        }
    }
    
    func shootTLPano() {
        let product = DJISDKManager.product()
        if let modelName = product?.model {
            let panoSettings = Hdrpano.getSettings(modelName: modelName)
            var grid: [[Float]]
                grid = Hdrpano.createGridSpheric(cols: panoSettings[1], rows: panoSettings[0],
                                                 maxGimb: Float(panoSettings[3]), maxNadir: Float(panoSettings[4]), Nb: 0)
            if Hdrpano.getSDPhotoCount() > grid.count { // Enough space on the sd card ?
                
                let error = DJISDKManager.missionControl()?.scheduleElements(Hdrpano.shootTLPano(grid: grid))
                
                if error != nil {
                    print("Error building timeline mission")
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        DJISDKManager.missionControl()?.startTimeline()
                    }
                }
            } else {
                print("SD card space")
            }
        }
    }
    
    func addKeyListener() {
        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: {(event: DJIMissionControlTimelineEvent,
            element: DJIMissionControlTimelineElement?, error: Error?, info: Any?) in
            
            if error != nil {
                print("Timeline Error in mission Control \((String(describing: error!)))")
            }
            
            let schedule = DJISDKManager.missionControl()?.currentTimelineMarker    // The task number during timelne
            let elements = DJISDKManager.missionControl()?.runningElement           // Running timeline element
            
            switch event {
            case .started:
                print("Timeline elements Element \(String(describing: elements)) Marker \(String(describing: schedule))")
            case .startError:
                print("Start error")
            case .paused:
                print("Paused \(String(describing: elements))")
            case .pauseError:
                print("Pause error \(String(describing: elements))")
            case .resumed:
                print("Resumed \(String(describing: elements))")
            case .resumeError:
                print("Resume error \(String(describing: elements))")
            case .stopped:
                print("Mission stopped successfully \(String(describing: elements))")
                Hdrpano.stopAdvancedVirtualStick()
                Hdrpano.resetGimbal()
                Hdrpano.setGimbalMode(gimbalMode: .yawFollow)
            case .stopError:
                print("Stop error \(String(describing: elements))")
            case .finished:
                print("Finished \(String(describing: elements))")
                if elements == nil {
                    print("Mission finished")
                    Hdrpano.stopAdvancedVirtualStick()
                    Hdrpano.resetGimbal()
                    Hdrpano.setGimbalMode(gimbalMode: .yawFollow)
                }
            default:
                break
            }
        })
    }
}

