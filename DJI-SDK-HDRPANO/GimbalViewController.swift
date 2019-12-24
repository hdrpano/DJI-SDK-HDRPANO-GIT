//
//  GimbalViewController.swift
//  DJI-SDK-HDRPANO
//
//  Created by Kilian Eisenegger on 23.12.19.
//  Copyright © 2019 Kilian Eisenegger. All rights reserved.
//

import UIKit
import Hdrpano

class GimbalViewController: UIView {
    
    var pitch: Double = 0.0 { didSet { setNeedsDisplay() } }
    
    override func draw(_ rect: CGRect) {
        Hdrpano.gimbalPitchDraw(pitch: pitch, rect: rect)
    }
}

