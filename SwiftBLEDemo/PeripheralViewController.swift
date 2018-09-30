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
        self.startButton?.isEnabled = false
        self.stopButton?.isEnabled = false
        self.logText?.sizeToFit()
        self.messageEdit?.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Action
    
    @IBAction func startClicked(sender: AnyObject) {
        self.manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [self.service.uuid]])
        self.startButton?.isEnabled = false
        self.stopButton?.isEnabled = true
    }
    
    @IBAction func stopClicked(sender: AnyObject) {
        self.manager.stopAdvertising()
        self.startButton?.isEnabled = true
        self.stopButton?.isEnabled = false
        self.addMessage(msg: "Stop advertisement")
    }
    
    // MARK: UITextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn) {
            self.addMessage(msg: "BLE Power On")
            self.addService()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if (error == nil) {
            self.addMessage(msg: "service is added!")
            self.startButton?.isEnabled = true
            self.stopButton?.isEnabled = false
        } else {
            self.addMessage(msg: "Failed to add service " + error!.localizedDescription)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if (error == nil) {
            self.addMessage(msg: "Start advertisement")
            self.data = self.messageEdit!.text!.data(using: String.Encoding.utf8)! as NSData
            self.messageEdit!.isEnabled = false
        } else {
            self.addMessage(msg: "Failed to start advertisement " + error!.localizedDescription)

        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        self.addMessage(msg: "Receive request")
        if (!request.characteristic.uuid.isEqual(self.characteristic.uuid)) {
            return
        }
        if (request.offset > data.length) {
            self.manager!.respond(to: request, withResult: CBATTError.invalidOffset)
            return;
        }
        // create data
        request.value = self.data!.subdata(with: NSMakeRange(request.offset, data.length - request.offset))
        self.manager!.respond(to: request, withResult: CBATTError.success);
        self.addMessage(msg: "Respond to request");
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
                                                      properties: CBCharacteristicProperties.read,
            value: nil, permissions:
            CBAttributePermissions.readable)
        self.service.characteristics = [self.characteristic]
        
        self.manager.add(self.service)
    }
}
