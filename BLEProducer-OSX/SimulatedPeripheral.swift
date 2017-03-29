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
    
    // serial queue for message processing
    private let queue = DispatchQueue(label: "queue.peripheral")
    
    private var manager : CBPeripheralManager!
    
    private var isAdvertising : Bool = false

    // collection of central manager references for subscribers
    private var subscribedCentrals : [CBCentral] = [CBCentral]()

    // food supply, slowly reduces at a fixed rate
    private var foodSupply : UInt = 0
    
    // interval in milliseconds for decrementing the food supply
    private let foodConsumptionInterval : UInt32
    
    // ticker timer
    private var foodConsumptionTimer : Timer!
    
    // stateUpdated handler to expose peripheral state
    var stateUpdatedHandler : (CBPeripheralManagerState) -> Void = { _ in }
    
    // valueUpdated handler to expose food supply
    var valueUpdatedHandler : (UInt) -> Void = { _ in }
    
    
    init(interval: UInt32) {
        self.foodConsumptionInterval = interval
        super.init()
        
        // initialize the peripheral manager
        self.manager = CBPeripheralManager(delegate: self, queue: self.queue)
        
        initCharacteristics()
        
        self.foodConsumptionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(interval), target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)

        NSLog("SimulatedPeripheral.init OK")
    }
    
    func startAdvertising(name: String, serviceId: String? = nil) {
        var advertisementData = [String:Any]()
        advertisementData[CBAdvertisementDataLocalNameKey] = name
        if let serviceId = serviceId {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = [CBUUID(string: serviceId)]
        }

        queue.async { [unowned self] in
            if self.isAdvertising {
                return
            }
            self.isAdvertising = true
            
            NSLog("startAdvertising(\(name))")
            self.manager.startAdvertising(advertisementData)
            
            self.randomizeFoodSupply()
            self.valueUpdatedHandler(self.foodSupply)
        }
    }
    
    func stopAdvertising() {
        queue.async { [unowned self] in
            if self.isAdvertising {
                NSLog("stopAdvertising")
                self.manager.stopAdvertising()
                
                self.isAdvertising = false
            }
        }
    }
    
    
    // MARK: - Peripheral Methods
    
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
            var message = [UInt8](request.value!)
            assert(message.count==1, "expected 1 byte")

            let value = UInt(message[0])
            NSLog("ack(\(request.hashValue), \(value))")
            peripheral.respond(to: request, withResult: .success)

            self.receiveFood(value)
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
    
    
    // MARK: - Private Methods
    
    private func initCharacteristics() {
        if let service = self.service {
            self.manager.remove(service as! CBMutableService)
        }

        let service = CBMutableService(type: Characteristics.service, primary: true)
        service.characteristics = [Characteristics.dead, Characteristics.food, Characteristics.feed]
        self.service = service
        self.manager.add(service)
    }
    
    private func randomizeFoodSupply() {
        self.foodSupply = UInt(arc4random_uniform(40) + 20)
    }
    
    // send "i'm dead" message
    private func sendDead() {
        NSLog("dead")
        let data = Data([0x01])
        queue.async { [unowned self] in
            self.manager.updateValue(data, for: Characteristics.dead, onSubscribedCentrals: self.subscribedCentrals)
        }
    }
    
    // send "feed me" message
    private func sendFeed() {
        NSLog("feed")
        let data = Data([0x01])
        queue.async { [unowned self] in
            self.manager.updateValue(data, for: Characteristics.feed, onSubscribedCentrals: self.subscribedCentrals)
        }
    }

    // receive food message
    private func receiveFood(_ value: UInt) {
        NSLog("food(\(value))")
        queue.async { [unowned self] in
            self.foodSupply += value
        }
    }
    
    // executes on main queue, driven by timer
    @objc private func tick() {
        queue.async { [unowned self] in
            if !self.isAdvertising {
                return
            }
            
            NSLog("tick(\(self.foodSupply))")
            if self.foodSupply == 1 {
                self.sendDead()
                self.stopAdvertising()
            }
            else if self.foodSupply > 1 {
                self.foodSupply -= 1
                if self.foodSupply < 10 {
                    self.sendFeed()
                }
            }
            self.valueUpdatedHandler(self.foodSupply)
        }
    }
    
}


// MARK: - 

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
