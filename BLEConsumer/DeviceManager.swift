//
//  DeviceManager.swift
//  BLEProducer
//
//  Created by Aubrey Goodman on 2/23/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import UIKit
import CoreBluetooth


class DeviceManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let instance = DeviceManager()
    
    var discoveredDeviceCallback : (PeripheralProxy) -> Void = { peripheral in }
    var updatedDeviceCallback : (PeripheralProxy) -> Void = { peripheral in }
    var connectedDeviceCallback : (PeripheralProxy) -> Void = { peripheral in }
    var disconnectedDeviceCallback : (PeripheralProxy) -> Void = { peripheral in }
    var stateCallback : (CBManagerState) -> Void = { state in }
    
    private let queue = DispatchQueue(label: "central.queue")
    private var bleManager : CBCentralManager!
    private var knownPeripherals = Set<PeripheralProxy>()
    private var connectedPeripherals = [UUID : CBPeripheral]()

    override init() {
        super.init()
        self.bleManager = CBCentralManager(delegate: self, queue: self.queue)
    }
    
    var stateUpdatedHandler : (CBManagerState) -> Void = { _ in }

    func startScanning() {
        self.bleManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        self.bleManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // reject advertisements without local name
        guard let _ = advertisementData[CBAdvertisementDataLocalNameKey] else {
            return
        }
        
        let filteredProxies = self.knownPeripherals.filter { (e: PeripheralProxy) -> Bool in
            return e.peripheral.identifier == peripheral.identifier
        }
        
        var proxy : PeripheralProxy? = nil
        var isExisting = false
        var isDirty = false
        if let existingProxy = filteredProxies.first {
            // update date on existing proxy; we use this to cull stale data
            proxy = existingProxy
            existingProxy.date = Date()
            isDirty = existingProxy.rssi != Int(RSSI)
            existingProxy.rssi = Int(RSSI)
            
            isExisting = true
        }
        else {
            proxy = PeripheralProxy(peripheral: peripheral, payload: advertisementData, rssi: Int(RSSI))
            self.knownPeripherals.insert(proxy!)
        }
        
        if isExisting {
            if isDirty {
                self.updatedDeviceCallback(proxy!)
            }
        }
        else {
            self.discoveredDeviceCallback(proxy!)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("state: \(central.state.toString())")
        self.stateUpdatedHandler(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        NSLog("willRestoreState: \(dict)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("failedToConnect: \(peripheral.name)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("connected: \(peripheral.name)")
        if let proxy = self.knownPeripherals.first(where: { (a: PeripheralProxy) -> Bool in
            return a.peripheral.identifier == peripheral.identifier
        }) {
            self.connectedPeripherals[peripheral.identifier] = peripheral
            self.connectedDeviceCallback(proxy)
            peripheral.delegate = self
            
            self.queue.async {
                NSLog("discoverServices")
                peripheral.discoverServices([CBUUID(string: "BABE")])
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("disconnected: \(peripheral.name)")
        if let proxy = self.knownPeripherals.first(where: { (a: PeripheralProxy) -> Bool in
            return a.peripheral.identifier == peripheral.identifier
        }) {
            self.disconnectedDeviceCallback(proxy)
        }
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        NSLog("peripheralDidUpdateName")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        NSLog("didDiscoverServices")
        self.queue.async {
            if let service = peripheral.services?.first {
                NSLog("discoverCharacteristics(\(service.uuid))")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        NSLog("didReadRSSI")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        NSLog("didModifyServices")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        NSLog("didWriteValueForDescriptor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        NSLog("didUpdateValueForDescriptor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        NSLog("didDiscoverCharacteristicsForService(\(service.uuid))")
        self.queue.async {
            if let service = peripheral.services?.first {
                for characteristic in service.characteristics! {
                    NSLog("subscribeTo(\(characteristic.uuid))")
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    if characteristic.uuid == CBUUID(string: "F00D") {
                        self.queue.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(1)) {
                            let message : [UInt8] = [0x01] // HI
                            let data = Data(bytes: message, count: 1)
                            NSLog("writeTo(\(characteristic.uuid), %x)", message[0])
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        NSLog("didDiscoverIncludedServicesForService")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("errorWritingValueForCharacteristic(\(characteristic.uuid), \(error))")
        }
        else {
            NSLog("didWriteValueForCharacteristic(\(characteristic.uuid))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("errorUpdatingValueFor(\(characteristic.uuid), \(error)")
        }
        else {
            let deadValue = [UInt8](characteristic.value!)
            NSLog("didUpdateValueForCharacteristic(\(characteristic.uuid), \(deadValue[0] == 0x01))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("errorDiscoveringDescriptorsFor(\(characteristic.uuid), \(error))")
        }
        else {
            NSLog("didDiscoverDescriptorsForCharacteristic(\(characteristic.uuid))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("errorUpdatingNotificationStateFor(\(characteristic.uuid), \(error))")
        }
        else {
            NSLog("didUpdateNotificationStateForCharacteristic(\(characteristic.uuid), \(characteristic.isNotifying))")
        }
    }
    
    // MARK: - Peripheral API
    
    func connect(_ proxy: PeripheralProxy) {
        bleManager.connect(proxy.peripheral, options: nil)
    }
    
    func disconnect(_ proxy: PeripheralProxy) {
        bleManager.cancelPeripheralConnection(proxy.peripheral)
    }
    
}

extension CBManagerState {
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

class PeripheralProxy : Hashable, Equatable {
    var date : Date
    var rssi : Int
    let payload : [String : Any]
    let peripheral : CBPeripheral
    
    var hashValue: Int {
        return peripheral.identifier.hashValue
    }
    
    init(peripheral: CBPeripheral, payload: [String : Any], rssi: Int) {
        self.peripheral = peripheral
        self.date = Date()
        self.rssi = rssi
        self.payload = payload
    }
    
    func localName() -> String {
        return self.payload[CBAdvertisementDataLocalNameKey] as! String
    }
    
    func serviceIds() -> [CBUUID] {
        let uuids = self.payload[CBAdvertisementDataServiceUUIDsKey] as! NSArray
        return uuids.map { return $0 as! CBUUID }
    }
}

func ==(a: PeripheralProxy, b: PeripheralProxy) -> Bool {
    return a.peripheral.identifier == b.peripheral.identifier
}
