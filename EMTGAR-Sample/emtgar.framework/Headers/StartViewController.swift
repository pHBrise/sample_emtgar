//
//  StartViewController.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 26/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//


import UIKit
import AVFoundation
import KudanAR
public class StartViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        ARAPIKey.sharedInstance().setAPIKey(kConfig.kudanKey)
        UIFont.jbs_registerFont(
            withFilenameString: "yugothil.ttf",
            bundle: Bundle().emtgarResourceBundle
        )
        UIFont.jbs_registerFont(
            withFilenameString: "yugothib.ttf",
            bundle: Bundle().emtgarResourceBundle
        )
        UIFont.jbs_registerFont(
            withFilenameString: "YuGothic-Bold.otf",
            bundle: Bundle().emtgarResourceBundle
        )
        UIFont.jbs_registerFont(
            withFilenameString: "YuGothic-Medium.otf",
            bundle: Bundle().emtgarResourceBundle
        )
        askUserForCameraPermission { (success) in
            if success {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContainerViewController") as! ContainerViewController
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            } else {
                self.authAVCaptureDeviceStatus()
            }
        }

    }
    
    func askUserForCameraPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (allowedAccess) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completion(allowedAccess)
            })
        })
    }
    
    @IBAction func touchUpInsiteStartBtn(_ sender: Any) {
        askUserForCameraPermission { (success) in
            if success {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContainerViewController") as! ContainerViewController
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            } else {
                self.authAVCaptureDeviceStatus()
            }
        }
    }
    
    //MARK: - AVCaptureDeviceStatus
    func authAVCaptureDeviceStatus() {
            let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            switch (authStatus){
            case .notDetermined:
                showAlert(title: "Unable to access the Camera", message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.")
            case .restricted:
                showAlert(title: "Unable to access the Camera", message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.")
            case .denied:
                showAlert(title: "Unable to access the Camera", message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.")
            case .authorized:break
            @unknown default:
                fatalError()
        }
    }
    
    func showAlert(title:String, message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertController.Style.alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)

        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
            // Take the user to Settings app to possibly change permission.
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        // Finished opening URL
                    })
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        })
        alert.addAction(settingsAction)

        self.present(alert, animated: true, completion: nil)
    }

}
