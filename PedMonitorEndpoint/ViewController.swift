//
//  ViewController.swift
//  PedMonitorEndpoint
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var intervalSlider: UISlider!
    @IBOutlet weak var pollingSwitch: UISwitch!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
    private var bluetoothManager: BluetoothManager!
    
    private let minInterval = 1
    private let maxInterval = 30
    private var currentInterval = 2
    
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        minLabel.text = "\(minInterval)"
        maxLabel.text = "\(maxInterval)"
        currentLabel.text = "\(currentInterval)"

        intervalSlider.minimumValue = Float(minInterval)
        intervalSlider.maximumValue = Float(maxInterval)
        intervalSlider.value = Float(currentInterval)
        
        intervalSlider.addTarget(self, action: #selector(intervalSliderDidEndSliding(notification:)), for: ([.touchUpInside,.touchUpOutside]))
        
        pollingSwitch.isOn = false
        pollingSwitch.isEnabled = false
        dataLabel.isHidden = true
        
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func intervalSliderChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let newInterval = Int(slider.value)
        if newInterval == currentInterval { return }
        currentInterval = newInterval
        currentLabel.text = "\(currentInterval)"
    }
    
    @objc func intervalSliderDidEndSliding(notification: NSNotification) {
        print("intervalSliderDidEndSliding \(Int(intervalSlider.value)) \(currentInterval)")
        updatePolling("dummy")
    }
    
    @IBAction func updatePolling(_ sender: Any) {
        log("updatePolling to \(pollingSwitch.isOn)")
        if pollingSwitch.isOn {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(currentInterval), repeats: true) { _ in
                self.bluetoothManager.updateNow()
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

extension ViewController: BluetoothManagerDelegate {
    
    func updateConnection(bluetoothConnection: BluetoothConnection) {
        log("updateConnection \(bluetoothConnection)")
        connectionLabel.text = bluetoothConnection.rawValue.capitalized + (bluetoothConnection == .searching ? "..." : "")
        if bluetoothConnection == .connected {
            pollingSwitch.isEnabled = true
            dataLabel.isHidden = false
            dataLabel.text = "..."
        } else {
            pollingSwitch.isOn = false
            pollingSwitch.isEnabled = false
        }
    }
    
    func updateData(data: String) {
        log("updateData \(data)")
        dataLabel.text = data
    }
    
}
