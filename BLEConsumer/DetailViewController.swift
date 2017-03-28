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

    var proxy : PeripheralProxy? = nil
    var connected : Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let proxy = self.proxy else {
            return
        }
        
        lblLocalName.text = proxy.localName()
        showConnectButton()
    }
    
    private func showConnectButton() {
        let button = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(connectButton))
        self.navigationItem.rightBarButtonItem = button
    }

    private func showDisonnectButton() {
        let button = UIBarButtonItem(title: "Disconnect", style: .plain, target: self, action: #selector(disconnectButton))
        self.navigationItem.rightBarButtonItem = button
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
        showDisonnectButton()
    }

    @IBAction func disconnectButton() {
        guard let proxy = self.proxy else {
            return
        }
        DeviceManager.instance.disconnect(proxy)
        showConnectButton()
    }

}

