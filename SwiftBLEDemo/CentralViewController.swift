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
        self.startButton?.enabled = false
        self.stopButton?.enabled = false
        self.logText?.sizeToFit()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startClicked(sender: AnyObject) {
        self.startButton?.enabled = false
        self.stopButton?.enabled = true
        self.manager.scanForPeripheralsWithServices([self.serviceUUID], options: nil)
        self.addMessage("Start scan")
    }
    
    @IBAction func stopClicked(sender: AnyObject) {
        self.manager.stopScan()
        self.addMessage("Stop scan")
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == CBCentralManagerState.PoweredOn {
            self.addMessage("BLE Power On")
            self.startButton?.enabled = true
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
            self.addMessage("Peripheral discovered")
            
            self.peripheral = peripheral
            self.peripheral.delegate = self
            self.manager.connectPeripheral(peripheral, options: nil)
            self.manager.stopScan()
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        self.addMessage("Connected to peripheral")
        self.peripheral.discoverServices([self.serviceUUID])
    }
    
    // MARK: CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if (error != nil) {
            self.addMessage("Failed to discover services " + error!.localizedDescription)
            return
        }
        let services : NSArray = peripheral.services
        self.addMessage("Service discovered count=\(services.count) services=\(services)")
        for service in services as! [CBService] {
            if service.UUID.isEqual(self.serviceUUID) {
                self.peripheral.discoverCharacteristics(nil, forService:service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error != nil {
            self.addMessage("Failed to discover characteristics " + error!.localizedDescription)
            return
        }
        let characteristics : NSArray = service.characteristics
        self.addMessage("Characteristics discovered count=\(characteristics.count) characteristics=\(characteristics)")
        for c in characteristics as! [CBCharacteristic] {
            self.addMessage("UUID=" + c.UUID!.UUIDString!)
            if c.UUID.isEqual(self.characteristicUUID) {
                self.peripheral.readValueForCharacteristic(c)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            self.addMessage("Failed to read value " + error!.localizedDescription)
            return
        }
        var data = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
        self.addMessage("value=\(data!)")
        
    }
    
    // MARK: private
    
    func addMessage(msg : String) {
        self.logText!.text = self.logText!.text! + "\n" + msg
    }

}