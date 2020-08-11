//
//  EMTGARView.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 8/6/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation
import UIKit

public class EMTGARVC: NSObject {
    static var emtgarStoryBoard: UIStoryboard {
        get {
            let frameworkBundle = Bundle(for: self)
            return UIStoryboard(name: "EMTGAR", bundle: frameworkBundle)
        }
    }

    public class func getBundleEmtgarFramework() -> Bundle? {
        var returnBundle:Bundle?
        if let bundlePath = Bundle.main.path(forResource: "emtgarResources", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) {
            let path = bundle.path(forResource: "...", ofType: nil)
            returnBundle = bundle
        } else {
            print("not found")
        }
        return returnBundle
    }
    
    public class func startARView() -> ContainerViewController {
        
        if #available(iOS 13.0, *) {
            let storyboard = UIStoryboard(name: "EMTGAR", bundle: Bundle().emtgarResourceBundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "ContainerViewController") as! ContainerViewController
            vc.modalPresentationStyle = .fullScreen
            return vc
        } else {
            // Fallback on earlier versions
            let storyboard = UIStoryboard(name: "EMTGAR", bundle: Bundle().emtgarResourceBundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "ContainerViewController") as! ContainerViewController
            vc.modalPresentationStyle = .fullScreen
            return vc
        }
    }
    
    public class func EMTGARView() -> EMTGARViewController {
        if #available(iOS 13.0, *) {
            let storyboard = UIStoryboard(name: "EMTGAR", bundle: Bundle().emtgarResourceBundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "EMTGARViewController") as! EMTGARViewController
            vc.modalPresentationStyle = .fullScreen
            return vc
        } else {
            // Fallback on earlier versions
            let storyboard = UIStoryboard(name: "EMTGAR", bundle: Bundle().emtgarResourceBundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "EMTGARViewController") as! EMTGARViewController
            vc.modalPresentationStyle = .fullScreen
            return vc
        }
    }
}
