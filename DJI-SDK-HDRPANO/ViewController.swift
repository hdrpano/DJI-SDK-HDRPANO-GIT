//
//  ViewController.swift
//  DJI-SDK-HDRPANO
//
//  Created by Kilian Eisenegger on 07.08.19.
//  Copyright © 2019 Kilian Eisenegger. All rights reserved.
//  Lesson 4
//

import UIKit
import DJISDK
import DJIUXSDK
import Hdrpano

class ViewController: DUXDefaultLayoutViewController, CLLocationManagerDelegate {
    @IBOutlet weak var missionStart: UIButton!
    @IBOutlet weak var missionStop: UIButton!
    @IBOutlet weak var gimbalPitch: GimbalViewController!   // There is an AircraftYawController too
    @IBOutlet weak var panoSettingsInfo: UILabel!           // This will indicate rows and columns
    @IBOutlet weak var customMapView: UIView!
    @IBOutlet weak var mapHeight: NSLayoutConstraint!
    @IBOutlet weak var mapWidth: NSLayoutConstraint!
    
    var mapViewController:DUXMapViewController?
    weak var mapWidget: DUXMapWidget?
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var locationManager: CLLocationManager!
    var isMapBig: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.missionStop.isHidden = true
        self.panoSettingsInfo.isHidden = true
        
        self.mapInit()
        
        self.contentViewController?.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.contentViewController?.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        self.contentViewController?.view.setNeedsDisplay()
        
        self.previewViewController?.view.isHidden = true
        self.dockViewController?.view.alpha = 0.75
        
        self.addKeyListener()
        
        self.gimbalPitch.pitch = 40 // This sets the graphical gimbal view to 0
    }
    
    @IBAction func missionStartAction(_ sender: UIButton) {
        if let isRunning = DJISDKManager.missionControl()?.isTimelineRunning, isRunning == false {
            /* Hdrpano.startAdvancedVirtualStick()
            self.shootTLPano()
            self.missionStop.isHidden = false
            self.panoSettingsInfo.isHidden = false */
            self.addAnnotation(lat: self.aircraftLocation.latitude, lon: self.aircraftLocation.longitude)
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
            Hdrpano.stopAdvancedVirtualStick()
        }
    }
    
    func shootTLPano() {
        let product = DJISDKManager.product()
        if let modelName = product?.model {
            let panoSettings = Hdrpano.getSettings(modelName: modelName)
            self.panoSettingsInfo.text = String(panoSettings[1]) + "x" + String(panoSettings[0])
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
        // Timeline in Progress Listener
        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: {(event: DJIMissionControlTimelineEvent,
            element: DJIMissionControlTimelineElement?, error: Error?, info: Any?) in
            
            if error != nil {
                print("Timeline Error in mission Control \((String(describing: error!)))")
            }
            
            let schedule = DJISDKManager.missionControl()?.currentTimelineMarker    // The task number during timelne
            let elements = DJISDKManager.missionControl()?.runningElement           // Running timeline element
            
            switch event {
            case .started:
                print("Timeline Element \(String(describing: elements)) Marker \(schedule!)")
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
            case .stopError:
                print("Stop error \(String(describing: elements))")
            case .finished:
                print("Finished \(String(describing: elements))")
                if schedule != nil {
                    self.missionStart.setTitle("Running " + String(Int(schedule!)/2), for: .normal)
                }
                if elements == nil {
                    print("Mission finished")
                    Hdrpano.stopAdvancedVirtualStick()
                    self.missionStop.isHidden = true
                    self.panoSettingsInfo.isHidden = true
                    self.missionStart.setTitle("Start Mission", for: .normal)
                    self.addAnnotation(lat: self.aircraftLocation.latitude, lon: self.aircraftLocation.longitude)
                }
            default:
                break
            }
        })
        
        // GimbalAttitude Listener
        if let gimbalAttitudeKey = DJIGimbalKey(param: DJIGimbalParamAttitudeInDegrees) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: gimbalAttitudeKey, withListener: self)
            { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
                
                if newValue != nil {
                    var gimbalAttitude = DJIGimbalAttitude() // Float in degrees
                    
                    let nsvalue = newValue!.value as! NSValue
                    nsvalue.getValue(&gimbalAttitude)
                    self.gimbalPitch.pitch = 40 - Double(gimbalAttitude.pitch)
                }
            }
        }
        
        // Aircraft Location Listener
        if let locationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)  {
           DJISDKManager.keyManager()?.startListeningForChanges(on: locationKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
               if newValue != nil {
                   let newLocationValue = newValue!.value as! CLLocation

                   if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                       self.aircraftLocation = newLocationValue.coordinate
                       
                   }
               }
           }
        }
        
    }
    
    func mapInit() {
        self.mapViewController = DUXMapViewController()
        self.mapWidget = self.mapViewController?.mapWidget!
        
        self.mapWidget?.translatesAutoresizingMaskIntoConstraints = false
        self.mapViewController?.willMove(toParent: self)
        self.addChild(self.mapViewController!)
        self.customMapView.addSubview(self.mapViewController!.mapWidget)
        self.mapViewController?.didMove(toParent: self)
        
        self.mapWidget?.topAnchor.constraint(equalTo: self.customMapView.topAnchor).isActive = true
        self.mapWidget?.bottomAnchor.constraint(equalTo: self.customMapView.bottomAnchor).isActive = true
        self.mapWidget?.leadingAnchor.constraint(equalTo: self.customMapView.leadingAnchor).isActive = true
        self.mapWidget?.trailingAnchor.constraint(equalTo: self.customMapView.trailingAnchor).isActive = true
        
        self.mapWidget?.showDirectionToHome = true
        self.mapWidget?.visibleFlyZones     = []
        self.mapWidget?.mapView.mapType     = .mutedStandard
        self.mapWidget?.showDirectionToHome = true
        self.mapWidget?.showFlightPath      = true
        self.mapWidget?.showHomeAnnotation  = true
        self.mapWidget?.showDJIAccountLoginIndicator = false
        self.mapWidget?.mapView.showsScale  = false
        self.mapWidget?.mapView.showsTraffic = true
        self.mapWidget?.mapView.showsBuildings = true
        self.mapWidget?.mapView.showsUserLocation = true
        
        let name = UIDevice.current.name
        if name.lowercased().range(of:"ipad") != nil {
           self.mapWidth.constant = 240
           self.mapHeight.constant = 200
        } else {
           if name.lowercased().range(of:"iphone x") != nil || name.lowercased().range(of:"iphone 6") != nil || name.lowercased().range(of:"iphone 11") != nil{
               self.mapHeight.constant = 75
           } else {
               self.mapHeight.constant = 85
           }
           self.mapWidth.constant = 200
        }
        
        self.mapWidget?.setNeedsDisplay()
        self.view.sendSubviewToBack(self.mapWidget!)
        
        if (CLLocationManager.locationServicesEnabled())
        {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestAlwaysAuthorization()

            //Zoom to user location
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let userLocation = self.locationManager.location?.coordinate {
                    let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 500, longitudinalMeters: 500)
                    self.mapWidget?.mapView.setRegion(viewRegion, animated: true)
                }
            }

            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func updateFlyZone() {
        self.mapWidget?.visibleFlyZones.insert([.restricted, .authorization])
        self.mapWidget?.visibleFlyZones.update(with: [.restricted, .authorization])
    }
    
    func addAnnotation(lat: Double, lon: Double) {
        let annotation = MKPointAnnotation()
        annotation.title = "POI Target"
        annotation.subtitle = "\(round3(lat))° \(round3(lon))°"
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.mapWidget?.mapView.addAnnotation(annotation)
        self.mapWidget?.setNeedsDisplay()
        print("addAnnotation lat\(round3(lat))° lon\(round3(lon))°")
    }
    
    func round3(_ value: Double) -> Double {
        return (value*1000).rounded()/1000
    }
    
    @IBAction func tabMap(_ sender: UILongPressGestureRecognizer) {
        guard sender.view != nil else { return }
        if sender.state == .ended {
            if self.isMapBig {
                let name = UIDevice.current.name
                if name.lowercased().range(of:"ipad") != nil {
                   self.mapWidth.constant = 240
                   self.mapHeight.constant = 200
                } else {
                   if name.lowercased().range(of:"iphone x") != nil || name.lowercased().range(of:"iphone 6") != nil || name.lowercased().range(of:"iphone 11") != nil{
                       self.mapHeight.constant = 75
                   } else {
                       self.mapHeight.constant = 85
                   }
                   self.mapWidth.constant = 200
                }
                
                self.isMapBig = false
                
                print("Map is small")
            } else {
                /* self.customMapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.customMapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.customMapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                self.customMapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true */
                
                self.mapWidth.constant = 500
                self.mapHeight.constant = 500
                self.isMapBig = true
                
                print("Map is big")
            }
        }
    }
    
    @IBAction func tabCustomMap(_ sender: UITapGestureRecognizer) {
        guard sender.view != nil else { return }
        if sender.state == .ended {
            if self.isMapBig {
                let name = UIDevice.current.name
                if name.lowercased().range(of:"ipad") != nil {
                   self.mapWidth.constant = 240
                   self.mapHeight.constant = 200
                } else {
                   if name.lowercased().range(of:"iphone x") != nil || name.lowercased().range(of:"iphone 6") != nil || name.lowercased().range(of:"iphone 11") != nil{
                       self.mapHeight.constant = 75
                   } else {
                       self.mapHeight.constant = 85
                   }
                   self.mapWidth.constant = 200
                }
                
                self.isMapBig = false
                
                print("Map is small")
            } else {
                /* self.customMapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.customMapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.customMapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                self.customMapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true */
                
                self.mapWidth.constant = self.view.frame.size.width / 2 - 50
                self.mapHeight.constant = self.view.frame.size.height - 60
                self.isMapBig = true
                
                print("Map is big")
            }
        }
    }
    
}

