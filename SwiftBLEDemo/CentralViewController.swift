//
//  CentralViewController.swift
//  SwiftBLEDemo
//
//  Created by fkm on 2015/09/12.
//  Copyright (c) 2015年 mokelab. All rights reserved.
//

import UIKit
import CoreBluetooth;

class CentralViewController : UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet var startButton : UIButton?
    @IBOutlet var stopButton : UIButton?
    @IBOutlet var logText : UILabel?
    
    var serviceUUID : CBUUID!
    var characteristicUUID : CBUUID!

    var manager : CBCentralManager!
    var peripheral : CBPeripheral!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.serviceUUID = CBUUID(string: Constants.SERVICE_UUID)
        self.characteristicUUID = CBUUID(string: Constants.CHARACTERISTIC_UUID)
        
        self.manager = CBCentralManager(delegate : self, queue : nil)
        self.startButton?.isEnabled = false
        self.stopButton?.isEnabled = false
        self.logText?.sizeToFit()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startClicked(sender: AnyObject) {
        self.startButton?.isEnabled = false
        self.stopButton?.isEnabled = true
        self.manager.scanForPeripherals(withServices: [self.serviceUUID], options: nil)
        self.addMessage(msg: "Start scan")
    }
    
    @IBAction func stopClicked(sender: AnyObject) {
        self.manager.stopScan()
        self.addMessage(msg: "Stop scan")
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.addMessage(msg: "BLE Power On")
            self.startButton?.isEnabled = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.addMessage(msg: "Peripheral discovered")
            
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.manager.connect(peripheral, options: nil)
        self.manager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.addMessage(msg: "Connected to peripheral")
        self.peripheral.discoverServices([self.serviceUUID])
    }
    
    // MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            self.addMessage(msg: "Failed to discover services " + error!.localizedDescription)
            return
        }
        let services : [CBService]? = peripheral.services
        self.addMessage(msg: "Service discovered count=\(services!.count) services=\(services!)")
        for service in services! {
            if service.uuid.isEqual(self.serviceUUID) {
                self.peripheral.discoverCharacteristics(nil, for:service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            self.addMessage(msg: "Failed to discover characteristics " + error!.localizedDescription)
            return
        }
        let characteristics : [CBCharacteristic]? = service.characteristics
        self.addMessage(msg: "Characteristics discovered count=\(characteristics!.count) characteristics=\(characteristics!)")
        for c in characteristics! {
            self.addMessage(msg: "UUID=" + c.uuid.uuidString)
            if c.uuid.isEqual(self.characteristicUUID) {
                self.peripheral.readValue(for: c)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            self.addMessage(msg: "Failed to read value " + error!.localizedDescription)
            return
        }
        let data = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        self.addMessage(msg: "value=\(data!)")
        
    }
    
    // MARK: private
    
    func addMessage(msg : String) {
        self.logText!.text = self.logText!.text! + "\n" + msg
    }

}
