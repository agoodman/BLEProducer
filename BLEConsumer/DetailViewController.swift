//
//  DetailViewController.swift
//  BLEConsumer
//
//  Created by Aubrey Goodman on 2/23/17.
//  Copyright © 2017 Aubrey Goodman. All rights reserved.
//

import UIKit


class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var lblLocalName : UILabel!
    @IBOutlet weak var btnFeed : UIButton!

    var proxy : PeripheralProxy? = nil
    var connected : Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let proxy = self.proxy else {
            return
        }
        
        lblLocalName.text = proxy.localName()
        showConnectButton()
        
        DeviceManager.instance.connectedDeviceCallback = { [unowned self] proxy in
            DispatchQueue.main.async { [unowned self] in
                self.showDisconnectButton()
                self.updateStateLabel(proxy)
            }
        }
        
        DeviceManager.instance.disconnectedDeviceCallback = { [unowned self] proxy in
            DispatchQueue.main.async { [unowned self] in
                self.showConnectButton()
            }
        }
        
        DeviceManager.instance.updatedDeviceCallback = { [unowned self] proxy in
            DispatchQueue.main.async { [unowned self] in
                self.updateStateLabel(proxy)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DeviceManager.instance.connectedDeviceCallback = { _ in }
        DeviceManager.instance.disconnectedDeviceCallback = { _ in }
    }
    
    private func showConnectButton() {
        let button = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(connectButton))
        self.navigationItem.rightBarButtonItem = button
    }

    private func showDisconnectButton() {
        let button = UIBarButtonItem(title: "Disconnect", style: .plain, target: self, action: #selector(disconnectButton))
        self.navigationItem.rightBarButtonItem = button
    }
    
    private func updateStateLabel(_ proxy: PeripheralProxy) {
        self.detailDescriptionLabel.text = proxy.stateString()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectButton() {
        guard let proxy = self.proxy else {
            return
        }
        DeviceManager.instance.connect(proxy)
    }

    @IBAction func disconnectButton() {
        guard let proxy = self.proxy else {
            return
        }
        DeviceManager.instance.disconnect(proxy)
    }

    @IBAction func sendFood() {
        DeviceManager.instance.sendFood(20, proxy: self.proxy!)
    }
    
}

