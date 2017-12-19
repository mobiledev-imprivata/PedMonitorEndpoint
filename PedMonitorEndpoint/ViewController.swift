//
//  ViewController.swift
//  PedMonitorEndpoint
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func updateNow(_ sender: Any) {
        log(#function)
        // bluetoothManager.updateNow()
    }

}

