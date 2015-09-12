//
//  PeripheralViewController.swift
//  SwiftBLEDemo
//
//  Created by fkm on 2015/09/12.
//  Copyright (c) 2015年 mokelab. All rights reserved.
//

import UIKit
import CoreBluetooth;

class PeripheralViewController : UIViewController, UITextFieldDelegate, CBPeripheralManagerDelegate {
    
    @IBOutlet var startButton : UIButton?
    @IBOutlet var stopButton : UIButton?
    @IBOutlet var messageEdit : UITextField?
    @IBOutlet var logText : UILabel?
    
    var serviceUUID : CBUUID!
    var characteristicUUID : CBUUID!
    
    var manager : CBPeripheralManager!
    var service : CBMutableService!
    var characteristic : CBMutableCharacteristic!
    var data : NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.manager = CBPeripheralManager(delegate : self, queue : nil)
        self.startButton?.enabled = false
        self.stopButton?.enabled = false
        self.logText?.sizeToFit()
        self.messageEdit?.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Action
    
    @IBAction func startClicked(sender: AnyObject) {
        self.manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [self.service.UUID]])
        self.startButton?.enabled = false
        self.stopButton?.enabled = true
    }
    
    @IBAction func stopClicked(sender: AnyObject) {
        self.manager.stopAdvertising()
        self.startButton?.enabled = true
        self.stopButton?.enabled = false
        self.addMessage("Stop advertisement")
    }
    
    // MARK: UITextField
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if (peripheral.state == CBPeripheralManagerState.PoweredOn) {
            self.addMessage("BLE Power On")
            self.addService()
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        if (error == nil) {
            self.addMessage("service is added!")
            self.startButton?.enabled = true
            self.stopButton?.enabled = false
        } else {
            self.addMessage("Failed to add service " + error!.localizedDescription)
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if (error == nil) {
            self.addMessage("Start advertisement")
            self.data = self.messageEdit!.text.dataUsingEncoding(NSUTF8StringEncoding)
            self.messageEdit!.enabled = false
        } else {
            self.addMessage("Failed to start advertisement " + error!.localizedDescription)

        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        self.addMessage("Receive request")
        if (!request.characteristic.UUID!.isEqual(self.characteristic.UUID)) {
            return
        }
        if (request.offset > data.length) {
            self.manager!.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            return;
        }
        // create data
        request.value = self.data!.subdataWithRange(NSMakeRange(request.offset, data.length - request.offset))
        self.manager!.respondToRequest(request, withResult: CBATTError.Success);
        self.addMessage("Respond to request");
    }
    
    // MARK: private
    
    func addMessage(msg : String) {
        self.logText!.text = self.logText!.text! + "\n" + msg
    }
    
    func addService() {
        self.serviceUUID = CBUUID(string: Constants.SERVICE_UUID)
        self.characteristicUUID = CBUUID(string: Constants.CHARACTERISTIC_UUID)

        self.service = CBMutableService(type: self.serviceUUID, primary: true)
        self.characteristic = CBMutableCharacteristic(type: self.characteristicUUID,
            properties: CBCharacteristicProperties.Read,
            value: nil, permissions:
            CBAttributePermissions.Readable)
        self.service.characteristics = [self.characteristic]
        
        self.manager.addService(self.service)
    }
}