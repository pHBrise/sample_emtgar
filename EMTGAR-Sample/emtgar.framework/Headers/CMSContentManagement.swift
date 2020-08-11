//
//  CMSContentManagement.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation

class CMSContentManagement:NSObject {

    var downloadTask: CMSNetworking?
    
    func getTotalFileSizeTrackables() -> Int {
        let trackableArray = CMSLoadDataFromFiles.getTrackables()
        return getTotalDownloadFileSize(downloadListArray: trackableArray)
    }
    
    func getTotalFileSizeMarkerContent(_ trackableName: String) -> Int {
        let markerContentArray = CMSLoadDataFromFiles.getContentFile(trackableName)
        return getTotalDownloadFileSize(downloadListArray: markerContentArray)
    }
    
    func getTotalFileSizeMarkerlessContent(_ fileData: ArtistFileData) -> Int {
        guard let markerlessFile = CMSLoadDataFromFiles.getMarkerlessFile(fileData) else {return 0}
        return getTotalDownloadFileSize(downloadListArray: [markerlessFile])
    }
    
    func getTrackables() -> [AnyHashable : Any] {
        let didFinishWithInternet = downloadTask?.downloadTrackables()
        let trackableArray = CMSLoadDataFromFiles.getTrackables()
        let dataDict = ["Trackables": trackableArray, "InternetConncection": didFinishWithInternet ?? false] as [String : Any]
        return dataDict
    }
    
    func getContentFile(_ trackableName: String) -> [AnyHashable : Any?] {
        let didFinishWithInternet = downloadTask?.downloadContentFile(trackableName)
        let contentFileArray = CMSLoadDataFromFiles.getContentFile(trackableName)
        let contentMarkerInfo = CMSLoadDataFromFiles.getContentMarkerInfo(trackableName)
        let dataDict = ["ContentFile": contentFileArray, "MarkerInfo": contentMarkerInfo, "InternetConncection": didFinishWithInternet ?? false] as [String : Any?]
        return dataDict
        
    }
    
    func getMarkerlessDetail() -> MarkerlessData? {
        return CMSLoadDataFromFiles.getLocalMarkerlessData()
    }
    
    func getMarkerlessFile(_ fileData: ArtistFileData) -> [AnyHashable : Any?] {
        let didFinishWithInternet = downloadTask?.downloadMarkerlessFile(fileData)
        let markerlessFile = CMSLoadDataFromFiles.getMarkerlessFile(fileData)
        let dataDict = ["MarkerlessFile": markerlessFile, "InternetConncection": didFinishWithInternet ?? false] as [String : Any?]
        return dataDict
        
    }
    
    // MARK: file management
    class func saveJSONMarkerData(toFolder markerData: MarkerData?) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first
        if let uwDocumentsDirectory = documentsDirectory {
            let dataPath = URL(fileURLWithPath: uwDocumentsDirectory).appendingPathComponent("JSON").relativePath
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("createDirectory error \(error.localizedDescription )")
                }
            }
            let filePath = URL(fileURLWithPath: dataPath).appendingPathComponent("/markerdata.json")
            if FileManager.default.fileExists(atPath: filePath.relativePath) {
                do {
                    try FileManager.default.removeItem(atPath: filePath.relativePath)
                } catch {
                    print("remove error \(error.localizedDescription )")
                }
            }
            do{
                let data = try? JSONEncoder().encode(markerData)
                try data?.write(to: filePath)
            } catch {
                print("write error \(error.localizedDescription )")
            }
        }

    }
    
    class func saveJSONMarkerlessData(toFolder markerData: MarkerlessData?) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first
        if let uwDocumentsDirectory = documentsDirectory {
            let dataPath = URL(fileURLWithPath: uwDocumentsDirectory).appendingPathComponent("JSON").relativePath
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("createDirectory error \(error.localizedDescription )")
                }
            }
            let filePath = URL(fileURLWithPath: dataPath).appendingPathComponent("/markerlessdata.json")
            if FileManager.default.fileExists(atPath: filePath.relativePath) {
                do {
                    try FileManager.default.removeItem(atPath: filePath.relativePath)
                } catch {
                    print("remove error \(error.localizedDescription )")
                }
            }
            do{
                let data = try? JSONEncoder().encode(markerData)
                try data?.write(to: filePath)
            } catch {
                print("write error \(error.localizedDescription )")
            }
        }
    }
    
    class func saveJsonArtisFileData(downloadListArray:[ArtistFileData]) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first
        if let uwDocumentsDirectory = documentsDirectory {
            let dataPath = URL(fileURLWithPath: uwDocumentsDirectory).appendingPathComponent("JSON").relativePath
            if !FileManager.default.fileExists(atPath: dataPath) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("createDirectory error \(error.localizedDescription )")
                }
            }
            let filePath = URL(fileURLWithPath: dataPath).appendingPathComponent("/filedata.json")
            if FileManager.default.fileExists(atPath: filePath.relativePath) {
                do {
                    try FileManager.default.removeItem(atPath: filePath.relativePath)
                } catch {
                    print("remove error \(error.localizedDescription )")
                }
                
            }
            do{
                let data = try? JSONEncoder().encode(downloadListArray)
                try data?.write(to: filePath)
            } catch {
                print("write error \(error.localizedDescription )")
            }
        }

    }

    class func writeCompletedFile(toDirectory directory: String?) {
        let completedFile = URL(fileURLWithPath: directory ?? "").appendingPathComponent("completed.txt").relativePath
        FileManager.default.createFile(atPath: completedFile, contents: nil, attributes: nil)
    }
    
    class func getFileDirectory(fromID fileID: Int?, withFormat fileFormat: String?) -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        let fileDirectory = URL(fileURLWithPath: bundleRoot ?? "").appendingPathComponent("Assets/\(fileFormat!)/\(fileID!)/").relativePath
        return fileDirectory
    }
    
    class func cleanTrackableFileDirectory(_ trackable: ArtistFileData?) {
        let fileManager = FileManager.default
        let directory = self.getFileDirectory(fromID: trackable?.fileData.id, withFormat: trackable?.fileData.format)
        if let uwDirectory = directory {
            var fileArray: [String]? = nil
            do {
                fileArray = try fileManager.contentsOfDirectory(atPath: uwDirectory)
                for filename in fileArray ?? [] {
                    do {
                        try fileManager.removeItem(atPath: URL(fileURLWithPath: uwDirectory).appendingPathComponent(filename).relativePath)
                        var jsonArtistFileData = CMSLoadDataFromFiles.getLocalArtistFileData()
                        jsonArtistFileData = jsonArtistFileData.filter({ (artistFileData) -> Bool in
                            return !(artistFileData == trackable!)
                        })
                        self.saveJsonArtisFileData(downloadListArray: jsonArtistFileData)
                    } catch {
                        print("cleanTrackableFileDirectory\(error.localizedDescription )")
                    }
                }
            } catch {
                print("cleanTrackableFileDirectory\(error.localizedDescription )")
            }
        }
    }
    
    func getTotalDownloadFileSize(downloadListArray:[ArtistFileData]) -> Int {
        let localFileDataArray = CMSLoadDataFromFiles.getLocalArtistFileData()
        var filterDownloadListArray:[ArtistFileData] = []
        var totalDownloadFileSize:Int = 0
        for localFile in localFileDataArray {
            filterDownloadListArray = downloadListArray.filter({ (downloadList) -> Bool in
                return !(downloadList.artistID == localFile.artistID && downloadList.fileData.id == localFile.fileData.id && downloadList.fileData.format == localFile.fileData.format && downloadList.fileData.checksum == localFile.fileData.checksum)
            })
        }
        for filterDownloadList in filterDownloadListArray {
            if let fileBytes = filterDownloadList.fileData.fileBytes {
                totalDownloadFileSize = totalDownloadFileSize + fileBytes
            }
        }
        return totalDownloadFileSize
    }
    
    
}
