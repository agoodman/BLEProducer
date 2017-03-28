//
//  SimulatedPeripheral.swift
//  BLEProducer
//
//  Simulates a peripheral having specified characteristics: DEAD, FEED, and F00D
//
//  DEAD: Bool (notify) - sent when food supply is exhausted
//
//  FEED: Bool (notify) - sent when food supply is low
//
//  F00D: UInt (write) - adds the given value to the food supply
//
//  Created by Aubrey Goodman on 2/23/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import CoreBluetooth


class SimulatedPeripheral: NSObject, CBPeripheralManagerDelegate {

    var service : CBService?
    
    private let queue = DispatchQueue(label: "queue.peripheral")
    private var manager : CBPeripheralManager!
    private var subscribedCentrals : [CBCentral] = [CBCentral]()

    // food supply, slowly reduces at a fixed rate
    private var foodSupply : UInt = 0
    
    // interval in milliseconds for decrementing the food supply
    private let foodConsumptionInterval : UInt32
    
    private var foodConsumptionTimer : Timer!
    
    // MARK: - Characteristics
    
    // DEAD: Bool (notify)
    private let dead = CBMutableCharacteristic(type: CBUUID(string: "DEAD"), properties: .notify, value: nil, permissions: .readable)
    
    // FEED: Bool (notify)
    private let feed = CBMutableCharacteristic(type: CBUUID(string: "FEED"), properties: .notify, value: nil, permissions: .readable)
    
    // F00D: UInt (write)
    private let food = CBMutableCharacteristic(type: CBUUID(string: "F00D"), properties: .write, value: nil, permissions: .writeable)

    var stateUpdatedHandler : (CBPeripheralManagerState) -> Void = { _ in }
    
    init(interval: UInt32) {
        self.foodConsumptionInterval = interval
        super.init()
        self.manager = CBPeripheralManager(delegate: self, queue: self.queue)
        
        self.randomizeFoodSupply()
        self.initCharacteristics()
        
        self.foodConsumptionTimer = Timer(timeInterval: TimeInterval(Double(interval) / 1000.0), repeats: true) { (timer: Timer) in
            if self.foodSupply == 1 {
                self.sendDead()
            }
            else {
                self.foodSupply -= 1
                if self.foodSupply < 10 {
                    self.sendFeed()
                }
            }
        }
    }
    
    func startAdvertising(name: String, serviceId: String? = nil) {
        NSLog("startAdvertising(\(name))")
        var advertisementData = [String:Any]()
        advertisementData[CBAdvertisementDataLocalNameKey] = name
        if let serviceId = serviceId {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = [CBUUID(string: serviceId)]
        }
        self.manager.startAdvertising(advertisementData)
    }
    
    func stopAdvertising() {
        NSLog("stopAdvertising")
        self.manager.stopAdvertising()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        NSLog("state: \(peripheral.state.toString())")
        self.stateUpdatedHandler(peripheral.state)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        NSLog("advertisingStarted")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        NSLog("didSubscribeTo(\(characteristic))")
        if !self.subscribedCentrals.contains(central) {
            self.subscribedCentrals.append(central)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        NSLog("didUnsubscribeFrom(\(characteristic))")
        if self.subscribedCentrals.contains(central) {
            self.subscribedCentrals.remove(at: self.subscribedCentrals.index(of: central)!)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        NSLog("didReceiveRead(\(request))")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        NSLog("didReceiveWrite(\(requests.count))")
        for request in requests {
            self.queue.async {
                var message = [UInt8](request.value!)
                NSLog("ack(\(request.hashValue), \(message[0]))")
                peripheral.respond(to: request, withResult: .success)

                if message.count == 1 && message[0] == 0x01 { // HI
                    peripheral.updateValue(Data([0x00]), for: self.dead, onSubscribedCentrals: self.subscribedCentrals)
                }
            }
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        NSLog("isReadyToUpdateSubscribers")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        NSLog("willRestoreState(\(dict))")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        NSLog("didAddService(\(service))")
    }
    
    
    func initCharacteristics() {
        if let service = self.service {
            self.manager.remove(service as! CBMutableService)
        }

        let service = CBMutableService(type: CBUUID(string: "5050"), primary: true)
        service.characteristics = [dead, food, feed]
        self.service = service
        self.manager.add(service)
    }
    
    private func randomizeFoodSupply() {
        self.foodSupply = UInt(arc4random_uniform(40) + 20)
    }
    
    private func sendDead() {
        let data = Data([0x01])
        self.manager.updateValue(data, for: dead, onSubscribedCentrals: self.subscribedCentrals)
    }
    
    private func sendFeed() {
        let data = Data([0x01])
        self.manager.updateValue(data, for: feed, onSubscribedCentrals: self.subscribedCentrals)
    }
    
}

extension CBPeripheralManagerState {
    func toString() -> String {
        switch self {
        case .poweredOff:
            return "PoweredOff"
        case .poweredOn:
            return "PoweredOn"
        case .resetting:
            return "Resetting"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        }
    }
}
