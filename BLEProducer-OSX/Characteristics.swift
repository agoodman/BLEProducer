//
//  Constants.swift
//  BLEProducer-OSX
//
//  Created by Aubrey Goodman on 3/28/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import CoreBluetooth

class Characteristics {
    
    
    // MARK: - Services
    
    static let service = CBUUID(string: "5050")
    
    
    // MARK: - Characteristics
    
    // DEAD: Bool (notify)
    static let dead = CBMutableCharacteristic(type: CBUUID(string: "DEAD"), properties: .notify, value: nil, permissions: .readable)
    
    // FEED: Bool (notify)
    static let feed = CBMutableCharacteristic(type: CBUUID(string: "FEED"), properties: .notify, value: nil, permissions: .readable)
    
    // F00D: UInt (write)
    static let food = CBMutableCharacteristic(type: CBUUID(string: "F00D"), properties: .write, value: nil, permissions: .writeable)

    
}
