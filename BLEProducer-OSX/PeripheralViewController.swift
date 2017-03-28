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
    @IBOutlet weak var characteristicValue : NSTextField!
    @IBOutlet weak var btnUpdateCharacteristic : NSButton!
    
    let peripheral = SimulatedPeripheral()
    
    private var value : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheral.stateUpdatedHandler = { state in
            DispatchQueue.main.async {
                self.lblState.stringValue = "\(state.toString())"
            }
        }
    }

    @IBAction func startAdvertising(_ sender: AnyObject) {
        peripheral.startAdvertising(name: "BLEProducer")
    }
    
    @IBAction func stopAdvertising(_ sender: AnyObject) {
        peripheral.stopAdvertising()
    }
    
    @IBAction func updateCharacteristic(_ sender: AnyObject) {
        self.value = self.characteristicValue.stringValue
        self.peripheral.updateCharacteristic(value: self.value!)
    }

}
