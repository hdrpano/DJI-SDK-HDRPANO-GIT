//
//  ViewController.swift
//  DJI-SDK-HDRPANO
//
//  Created by Kilian Eisenegger on 07.08.19.
//  Copyright © 2019 Kilian Eisenegger. All rights reserved.
//

import UIKit
import DJIUXSDK
import Hdrpano

class ViewController: DUXDefaultLayoutViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.contentViewController?.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.contentViewController?.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        self.contentViewController?.view.setNeedsDisplay()
    }
    
}

