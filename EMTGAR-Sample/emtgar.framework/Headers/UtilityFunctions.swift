//
//  UtilityFunctions.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class UtilityFunctions: NSObject {
    func checkSum(local:String, isEqualTo remote:String)  -> Bool {
        if local == remote {
            return true
        }
        return false
    }
    
    class func isfileExits(fileDownloadInfo:FileData) -> Bool {
        let fileManager = FileManager.default

        let pathForFile: String? = nil

        if fileManager.fileExists(atPath: pathForFile ?? "") {
        }

        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        let destinationDir = URL(fileURLWithPath: bundleRoot ?? "").appendingPathComponent("Assets/\(fileDownloadInfo.format!)/\(fileDownloadInfo.id!)/\(fileDownloadInfo.fileName!)").relativePath

        if fileManager.fileExists(atPath: destinationDir) {
            return true
        }
        return false
    }
    
    class func isfileExits(stringPathComponent:String) -> Bool {
        let fileManager = FileManager.default

        let pathForFile: String? = nil

        if fileManager.fileExists(atPath: pathForFile ?? "") {
        }

        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        let destinationDir = URL(fileURLWithPath: bundleRoot ?? "").appendingPathComponent("Assets/\(stringPathComponent)").relativePath

        if fileManager.fileExists(atPath: destinationDir) {
            return true
        }
        return false
    }

    
    class func isConnectedToCellular() -> Bool {
        do {
            if try Reachability().connection == .cellular {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    class func parseConfig() -> ARConfig {
        let path = Bundle.main.path(forResource: "ConfigLib", ofType: "plist")
        let url = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try! decoder.decode(ARConfig.self, from: data)
    }

  class func image(with view: UIView) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
      defer { UIGraphicsEndImageContext() }
      if let context = UIGraphicsGetCurrentContext() {
          view.layer.render(in: context)
          let image = UIGraphicsGetImageFromCurrentImageContext()
          return image
      }
      return nil
  }
    
}

