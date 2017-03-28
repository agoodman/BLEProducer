//
//  MasterViewController.swift
//  BLEConsumer
//
//  Created by Aubrey Goodman on 2/23/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import UIKit
import CoreBluetooth


class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [PeripheralProxy]()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        DeviceManager.instance.stateUpdatedHandler = { state in
            NSLog("bleState: \(state.toString())")
        }
        DeviceManager.instance.discoveredDeviceCallback = { proxy in
            let localName = proxy.payload[CBAdvertisementDataLocalNameKey]
            let serviceUUIDs : NSArray? = proxy.payload[CBAdvertisementDataServiceUUIDsKey] as? NSArray
            let mfgData = proxy.payload[CBAdvertisementDataManufacturerDataKey]
            let overflowServiceUUIDs = proxy.payload[CBAdvertisementDataOverflowServiceUUIDsKey]
            let serviceUUIDStrings = serviceUUIDs?.map { return $0 as! CBUUID }.map { return $0.uuidString }
            
            NSLog("discovered(rssi: \(proxy.rssi), name: \(proxy.peripheral.name), description: \(proxy.peripheral.identifier), localName: \(localName), serviceUUIDs: \(serviceUUIDStrings), mfgData: \(mfgData), overflowServiceUUIDs: \(overflowServiceUUIDs))")

            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.objects.insert(proxy, at: 0)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        }
        DeviceManager.instance.updatedDeviceCallback = { proxy in
            let localName = proxy.payload[CBAdvertisementDataLocalNameKey]
            
            NSLog("updated(name: \(localName), rssi: \(proxy.rssi))")
            
            DispatchQueue.main.async {
                if let index = self.objects.index(of: proxy) {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DeviceManager.instance.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DeviceManager.instance.stopScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.proxy = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object : PeripheralProxy = objects[indexPath.row]
        cell.textLabel!.text = object.localName()
        cell.detailTextLabel!.text = String(format: "%d", object.rssi)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

