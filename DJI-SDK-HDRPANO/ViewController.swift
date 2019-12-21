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
    @IBOutlet weak var missionStop: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.missionStop.isHidden = true
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
            self.missionStop.isHidden = false
        } else {
            if let isPaused = DJISDKManager.missionControl()?.isTimelinePaused, isPaused == false {
                DJISDKManager.missionControl()?.pauseTimeline()
                self.missionStart.setTitle("Resume", for: .normal)
            } else {
                DJISDKManager.missionControl()?.resumeTimeline()
            }
        }
    }
    
    @IBAction func stopMissionAction(_ sender: UIButton) {
        if let isRunning = DJISDKManager.missionControl()?.isTimelineRunning, isRunning == true {
            DJISDKManager.missionControl()?.stopTimeline()
            DJISDKManager.missionControl()?.unscheduleEverything()
        }
        Hdrpano.stopAdvancedVirtualStick()
    }
    
    func shootTLPano() {
        let product = DJISDKManager.product()
        if let modelName = product?.model {
            let panoSettings = Hdrpano.getSettings(modelName: modelName)
            var grid: [[Float]]
                grid = Hdrpano.createGridSpheric(cols: panoSettings[1], rows: panoSettings[0],
                                                 maxGimb: Float(panoSettings[3]), maxNadir: Float(panoSettings[4]), Nb: 0)
            if Hdrpano.getSDPhotoCount() > grid.count { // Enough space on the sd card ?
                DJISDKManager.missionControl()?.unscheduleEverything()
                let error = DJISDKManager.missionControl()?.scheduleElements(Hdrpano.shootTLPano(grid: grid))
                
                if error != nil {
                    print("Error building timeline mission")
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        DJISDKManager.missionControl()?.startTimeline()
                    }
                }
            } else {
                print("Not enough SD card space")
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
                print("Timeline Element \(elements!) Marker \(schedule!)")
            case .startError:
                print("Start error")
            case .paused:
                print("Paused \(elements!)")
            case .pauseError:
                print("Pause error \(elements!)")
            case .resumed:
                print("Resumed \(elements!)")
            case .resumeError:
                print("Resume error \(elements!)")
            case .stopped:
                print("Mission stopped successfully \(elements!)")
                Hdrpano.stopAdvancedVirtualStick()
            case .stopError:
                print("Stop error \(elements!)")
            case .finished:
                print("Finished \(elements!))")
                self.missionStart.setTitle("Running" + String(Int(schedule!)/2), for: .normal)
                if elements == nil {
                    print("Mission finished")
                    Hdrpano.stopAdvancedVirtualStick()
                    self.missionStop.isHidden = true
                    self.missionStart.setTitle("Start Mission", for: .normal)
                }
            default:
                break
            }
        })
    }
}

