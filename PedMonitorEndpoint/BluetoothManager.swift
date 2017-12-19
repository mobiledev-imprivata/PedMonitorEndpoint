//
//  BluetoothManager.swift
//  PedMonitorEndpoint
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BluetoothConnection: String {
    case disconnected, searching, connected
}

protocol BluetoothManagerDelegate {
    func updateConnection(bluetoothConnection: BluetoothConnection)
    func updateData(data: String)
}

final class BluetoothManager: NSObject {
    
    private let serviceUUID                     = CBUUID(string: "B6108A9B-BF75-456B-8DCB-6942F2A3E5BA")
    private let setIntervalCharacteristicUUID   = CBUUID(string: "AB519B66-6215-48D8-8727-4D41FB35DA8F")
    private let getMotionDataCharacteristicUUID = CBUUID(string: "9D5F61B3-23E9-4812-8AF3-9536B9ADAC46")

    private let timeoutInSecs = 5.0
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var setIntervalCharacteristic: CBCharacteristic!
    private var getMotionDataCharacteristic: CBCharacteristic!
    
    private var isPoweredOn = false
    private var scanTimer: Timer!
    
    var delegate: BluetoothManagerDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    private func startScanForPeripheral(serviceUuid: CBUUID) {
        log("startScanForPeripheral")
        
        centralManager.stopScan()
        scanTimer = Timer.scheduledTimer(timeInterval: timeoutInSecs, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        centralManager.scanForPeripherals(withServices: [serviceUuid], options: nil)
        
        delegate?.updateConnection(bluetoothConnection: .searching)
    }
    
    // can't be private because called by timer
    @objc func timeout() {
        log("timed out")
        centralManager.stopScan()
        delegate?.updateConnection(bluetoothConnection: .disconnected)
    }
    
    func updateNow() {
        let data = "10.0".data(using: .utf8)!
        peripheral.writeValue(data, for: setIntervalCharacteristic, type: .withResponse)
    }
    
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var caseString: String!
        switch central.state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        log("centralManagerDidUpdateState \(caseString!)")
        isPoweredOn = centralManager.state == .poweredOn
        if isPoweredOn {
            startScanForPeripheral(serviceUuid: serviceUUID)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log("centralManager didDiscoverPeripheral")
        scanTimer.invalidate()
        centralManager.stopScan()
        self.peripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("centralManager didConnectPeripheral")
        self.peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let message = "peripheral didDiscoverServices " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for service in peripheral.services! {
            log("service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let invalidatedUuids = invalidatedServices.map { $0.uuid }
        let message = "peripheral didModifyServices invalidatedServices: \(invalidatedServices.count) \(invalidatedUuids)"
        log(message)
        if !invalidatedUuids.isEmpty {
            delegate?.updateConnection(bluetoothConnection: .disconnected)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let message = "peripheral didDiscoverCharacteristicsFor service " + (error == nil ? "\(service.uuid.uuidString) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for characteristic in service.characteristics! {
            log("characteristic \(characteristic.uuid.uuidString)")
            if characteristic.uuid == setIntervalCharacteristicUUID {
                self.setIntervalCharacteristic = characteristic
            } else  if characteristic.uuid == getMotionDataCharacteristicUUID {
                self.getMotionDataCharacteristic = characteristic
            }
        }
        delegate?.updateConnection(bluetoothConnection: .connected)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let message = "peripheral didWriteValueFor characteristic " + (error == nil ? "\(characteristic.uuid.uuidString) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        peripheral.readValue(for: getMotionDataCharacteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let message = "peripheral didUpdateValueFor characteristic " + (error == nil ? "\(characteristic.uuid.uuidString) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        let response = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
        log(response)
        delegate?.updateData(data: response)
    }
    
}
