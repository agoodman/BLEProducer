//
//  PeripheralViewController.swift
//  BLEProducer-OSX
//
//  Created by Aubrey Goodman on 2/23/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import Cocoa

class PeripheralViewController: NSViewController {

    @IBOutlet weak var btnStartAdvertising : NSButton!
    @IBOutlet weak var btnStopAdvertising : NSButton!
    @IBOutlet weak var lblState : NSTextField!
    @IBOutlet weak var lblFoodSupply : NSTextField!
    
    let peripheral = SimulatedPeripheral(interval: 1)
    
    private var value : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheral.stateUpdatedHandler = { state in
            DispatchQueue.main.async {
                self.lblState.stringValue = "\(state.toString())"
            }
        }
        
        peripheral.valueUpdatedHandler = { value in
            DispatchQueue.main.async {
                self.lblFoodSupply.stringValue = "\(value)"
            }
        }
        
        btnStartAdvertising.isEnabled = true
        btnStopAdvertising.isEnabled = false
    }

    @IBAction func startAdvertising(_ sender: AnyObject) {
        peripheral.startAdvertising(name: "BLEProducer")
        btnStartAdvertising.isEnabled = false
        btnStopAdvertising.isEnabled = true
    }
    
    @IBAction func stopAdvertising(_ sender: AnyObject) {
        peripheral.stopAdvertising()
        btnStartAdvertising.isEnabled = true
        btnStopAdvertising.isEnabled = false
    }
    
}
