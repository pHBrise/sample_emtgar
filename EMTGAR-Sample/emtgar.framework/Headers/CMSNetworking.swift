//
//  CMSNetworking.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation
import UIKit

protocol CMSDownloadProgress: NSObjectProtocol {
    func updateProgressView(_ percentage: NSNumber?)
    func startDownloadProgressView()
    func downloadFinishedLoadTrackable()
}

class CMSNetworking: NSObject, NSURLConnectionDataDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    private var jsonData: Data?
    private var locaJSONData: Data?
    private var jsonRemoteArray: [AnyHashable]? = []
    private var jsonLocalArray: [AnyHashable]?
    private var arrFileDownloadData: [CMSFileDownloadMeta] = []
    private var downloadListArray: [ArtistFileData] = []
//    private var localFileDataArray: [ArtistFileData] = []
    private var session: URLSession?
    private var didCompleteWithInternet = false
    
    weak var progressDelegate: CMSDownloadProgress?
//    lazy var userAgentHeader: String = {
//        let deviceModel = UIDevice.current.model
//        let platform = "ios";
//        let platformVersion = UIDevice.current.systemVersion;
//        let locale = NSLocale.autoupdatingCurrent.languageCode!
//        let uid = "21d62d1e0a404e3060511fb5f12d6359"
//        let aid = "9a419a1867e5ab85abe068d09004c564"
//        let appID = "";
//        let appVersion = "";
//        let device = deviceModel + ",(" + platform + "," + platformVersion + ")";
//        let header = "VRMODE/" + device + ";"
//            + KEY_LOCALE + ":" + locale + ";" +
//            KEY_BOUNDARY +
//            KEY_UID + ":" + uid + ";" +
//            KEY_AID + ":" + aid + ";" +
//            KEY_VERSION + ":" + appVersion + ";" +
//            KEY_APP_ID + ":" + appID;
//        return header
//    }()
    
    func downloadTrackables() -> Bool {
        didCompleteWithInternet = true
        setupSession()
        loadDownloadMarkerFileInformation()
        initializeFileDownloadDataArray()
        updateProgress({
            let downloadCompleteList = self.updateDownloadCompleteList()
            CMSContentManagement.saveJsonArtisFileData(downloadListArray: downloadCompleteList)
            self.progressDelegate?.downloadFinishedLoadTrackable()
        })
        
        return didCompleteWithInternet
    }
    
    func downloadContentFile(_ trackableName: String?) -> Bool {
        didCompleteWithInternet = true
        setupSession()
        if let markerData =  CMSLoadDataFromFiles.getLocalMarkerData() {
            self.downloadListArray = self.getFileMarkerDataArray(markerData: markerData, trackName: trackableName)
        }
        loadDownloadMarkerFileInformation(trackName: trackableName)
        initializeFileDownloadDataArray()
        updateProgress({
            let downloadCompleteList = self.updateDownloadCompleteList()
            CMSContentManagement.saveJsonArtisFileData(downloadListArray: downloadCompleteList)
            self.progressDelegate?.downloadFinishedLoadTrackable()
        })
        return didCompleteWithInternet
    }
    
    func downloadMarkerlessFile(_ fileData: ArtistFileData) -> Bool {
        didCompleteWithInternet = true
        setupSession()
        downloadListArray = [fileData]
        loadDownloadMarkerFileInformation()
        initializeFileDownloadDataArray()
        updateProgress({
            let downloadCompleteList = self.updateDownloadCompleteList()
            CMSContentManagement.saveJsonArtisFileData(downloadListArray: downloadCompleteList)
            self.progressDelegate?.downloadFinishedLoadTrackable()
        })
        
        return didCompleteWithInternet
    }
    
//    func getMarkerlessData(_ completion:@escaping(MarkerlessData?) -> Void) {
//        var markerlessData:MarkerlessData?
//        var urlString = markerlessURL
//        if kConfig.develop {urlString = devMarkerlessURL}
//        let url = URL(string: urlString)
//        do {
//            if let url = url {
//                let data = try Data(contentsOf: url)
//                markerlessData = try JSONDecoder().decode(MarkerlessData.self, from: data)
//                CMSContentManagement.saveJSONMarkerlessData(toFolder: markerlessData)
//                completion(markerlessData)
//            }
//        } catch {
//            print(error)
//            completion(markerlessData)
//        }
//
//    }
    
    @objc func updateProgress(_ completionHandler: @escaping () -> Void) {
        while !checkAllFilesCompleted() {
            var progress: Double = 0
            
            for tDl in arrFileDownloadData {
                progress += tDl.downloadProgress
            }
            progress = progress / Double(arrFileDownloadData.count)
            if progressDelegate != nil {
                assert((progressDelegate != nil) && ((progressDelegate?.responds(to: #selector(updateProgress(_:)))) != nil), "CMSNetworking requires a delegate which responds to updateProgressView:")
                progressDelegate!.updateProgressView(NSNumber(value: progress))
            } else {
                print("progressDelegate nil")
            }
            
        }
        completionHandler()
    }
    
    
    func setupSession() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpMaximumConnectionsPerHost = 5
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    // Starts downloads
    func initializeFileDownloadDataArray() {
        if arrFileDownloadData.count > 0 {
            progressDelegate?.startDownloadProgressView()
        }
        for toDl in arrFileDownloadData {
            if let url = URL(string: toDl.downloadSource!) {
                guard let basicAuth = getBasicAuth(username: "ajtja", password: "dmwmd") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
                request.setValue(userAgentHeader, forHTTPHeaderField:"User-Agent")
                toDl.downloadTask = session?.downloadTask(with: request)
            }
            toDl.taskIdentifier = toDl.downloadTask!.taskIdentifier
            toDl.downloadTask!.resume()
            toDl.isDownloading = true
        }
    }
    
    func requestURL(url:URL, completionHandler: @escaping (_ data:Data?,_ response: URLResponse?,_ error: Error?) -> Void)  {
        print("requestURL \(url.absoluteString)")
        guard let basicAuth = getBasicAuth(username: "ajtja", password: "dmwmd") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
        print("userAgentHeader: \(userAgentHeader)")
        request.setValue(userAgentHeader, forHTTPHeaderField:"User-Agent")
        request.timeoutInterval = 60.0
        URLSession.shared.dataTask(with: request) {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            completionHandler(data,response,error)
        }.resume()
        
    }
    
    func getBasicAuth(username:String, password:String) -> String? {
        let loginString = "\(username):\(password)"
        return loginString.data(using: String.Encoding.utf8)?.base64EncodedString()
    }
    
    // 1
    func getJSONFileMarkerDataFromURL(trackName: String? = nil,completionHandler:@escaping(_ success:Bool)->Void) {
        var result:Bool = false
        var urlString = markerURL
        if kConfig.develop {urlString = devMarkerURL}
        let url = URL(string: urlString + "?\(serviceID)=" + kConfig.memberAuthServiceId)
        if let _url = url {
            requestURL(url: _url) { (data, response, error) in
                if let _data = data {
                    do {
                        let markerData = try JSONDecoder().decode(MarkerData.self, from: _data)
                        CMSContentManagement.saveJSONMarkerData(toFolder: markerData)
                        self.downloadListArray = self.getFileMarkerDataArray(markerData: markerData, trackName: trackName)
                        result = true
                    } catch {
                        print("JSONFileMarkerData \(String(data: _data, encoding: .utf8) ?? "utf8 Encode nil")")
                    }
                }
                completionHandler(result)
            }
        } else {
            completionHandler(result)
        }
        
    }
    
    func getJSONFileMarkerlessDataFromURL(completionHandler:@escaping(_ success:Bool)->Void) {
        var result:Bool = false
        var urlString = markerlessURL
        if kConfig.develop {urlString = devMarkerlessURL}
        let url = URL(string: urlString + "?\(serviceID)=" + kConfig.memberAuthServiceId)
        if let _url = url {
            requestURL(url: _url) { (data, response, error) in
                if let _data = data {
                    do {
                        let markerlessData = try JSONDecoder().decode(MarkerlessData.self, from: _data)
                        CMSContentManagement.saveJSONMarkerlessData(toFolder: markerlessData)
                        result = true
                    } catch {
                        print("JSONFileMarkerlessData \(String(data: _data, encoding: .utf8) ?? "utf8 Encode nil")")
                        print("decode MarkerlesData: \(error)")
                    }
                }
                completionHandler(result)
            }
        } else {
            completionHandler(result)
        }
        
    }
    
    func getMemberStatus(memberStatusID:Int, cid:[Int]?, completionHandler:@escaping(_ status:Int?)->Void) {
        var memberStatus:Int?
        var url:URL!
        
        var urlString = memberAuthURL
        if kConfig.develop {urlString = devMemberAuthURL}
        if let _cid = cid {
            var cidStr = "cid="
            for numCid in _cid {
                if numCid == _cid.last {
                    cidStr.append("\(numCid)")
                } else {
                    cidStr.append("\(numCid),")
                }
            }
            print(cidStr)
            url = URL(string: urlString + "\(memberStatusID)&\(cidStr)")
        } else {
            url = URL(string: urlString + "\(memberStatusID)")
        }
        
        if let _url = url {
            requestURL(url: _url) { (data, response, error) in
                if let _data = data {
                    if let res = response as? HTTPURLResponse {
                        if res.statusCode == 200 {
                            do {
                                let member = try JSONDecoder().decode(Member.self, from: _data)
                                if let status = member.status {
                                    memberStatus = status
                                }
                            } catch {
                                
                            }
                            
                        }
                    }
                    print("getMemberStatus \(String(data: _data, encoding: .utf8) ?? "utf8 Encode nil")")
                }
                completionHandler(memberStatus)
            }
        } else {
            completionHandler(memberStatus)
        }
    }
    
    // 2
    func getFileMarkerDataArray(markerData:MarkerData?,trackName:String?) -> [ArtistFileData]  {
        var temp:[ArtistFileData] = []
        guard let _markerData = markerData else {return temp}
        if let _trackName = trackName {
            //contentFile
            let trackArray = _trackName.components(separatedBy: "artisId")
            guard let _contentInfo = trackArray.first, let _artisId = trackArray.last else { return temp }
            
            guard let markerDetail = _markerData.details else {return temp}
            guard let markerArtistDataArray = markerDetail.artistData else {return temp}
            let artisfilter = markerArtistDataArray.filter { (markerArtistDataArray) -> Bool in
                guard let artistId = markerArtistDataArray.artistID else {return false}
                return "\(artistId)" == _artisId
            }
            if artisfilter.count == 1 {
                let artist = artisfilter[0]
                guard let markersInfo = artist.markersInfo else { return temp }
                let markersInfoFilter = markersInfo.filter { (markersInfo) -> Bool in
                    guard let code = markersInfo.code else {return false}
                    return code == _contentInfo
                }
                if markersInfoFilter.count == 1 {
                    let markerInfo = markersInfoFilter[0]
                    guard let artisID = artist.artistID else {return temp}
                    guard let thumbnailFiledata = markerInfo.thumbnailFiledata else { return temp }
                    let downloadList = ArtistFileData(artistID: artisID, fileData: thumbnailFiledata)
                    temp.append(downloadList)
                    guard let contentInfo = markerInfo.contentInfo else { return temp }
                    guard let contentFiledataArray = contentInfo.contentFiledata else { return temp }
                    for contentFiledata in contentFiledataArray {
                        let downloadList = ArtistFileData(artistID: artisID, fileData: contentFiledata)
                        temp.append(downloadList)
                    }
                }
            }
            return temp
        } else {
            //markerfile
            guard let markerDetail = _markerData.details else {return temp}
            guard let markerArtistDataArray = markerDetail.artistData else {return temp}
            for markerArtistData in markerArtistDataArray {
                guard let artisId = markerArtistData.artistID else {return temp}
                guard let karmarkerFiledata = markerArtistData.karmarkerFiledata else {return temp}
                let downloadList = ArtistFileData(artistID: artisId, fileData: karmarkerFiledata)
                temp.append(downloadList)
            }
            print("karmarkerFiledata \(temp )")
            return temp
        }
    }
    
    // 3
    func loadDownloadMarkerFileInformation(trackName: String? = nil) {
        let localFileDataArray = CMSLoadDataFromFiles.getLocalArtistFileData()
        var temp: [CMSFileDownloadMeta] = []
        for localFile in localFileDataArray {
            downloadListArray = downloadListArray.filter({ (downloadList) -> Bool in
                return !(downloadList.artistID == localFile.artistID && downloadList.fileData.id == localFile.fileData.id && downloadList.fileData.format == localFile.fileData.format && downloadList.fileData.checksum == localFile.fileData.checksum)
            })
        }
        for download in downloadListArray {
            addFileData(download, toDownloadList: &temp)
        }
        print("arrFileDownloadData: \(arrFileDownloadData)")
        arrFileDownloadData = temp
    }
    
    func isfileExits(fileDownloadInfo:FileData) -> Bool {
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        
        if let uwBundleRoot = bundleRoot {
            let destinationDir = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent("Assets/\(fileDownloadInfo.format!)/\(fileDownloadInfo.id!)/\(fileDownloadInfo.fileName!)").relativePath
            
            if fileManager.fileExists(atPath: destinationDir) {
                return true
            }
        }
        
        return false
    }
    
    func addFileData(_ downloadList: ArtistFileData, toDownloadList array: inout [CMSFileDownloadMeta]) {
        var fileURL: String? = nil
        var urlString = downloadURL
        if kConfig.develop {urlString = devDownloadURL}
        if let id = downloadList.fileData.id, let format = downloadList.fileData.format {
            fileURL = "\(urlString)?\(serviceID)=\(kConfig.memberAuthServiceId)&fid=\(id)&format=\(format)&type=marker&artist_id=\(downloadList.artistID)"
        }
        array.append(CMSFileDownloadMeta(fileTitle: downloadList.fileData.fileName, andDownloadSource: fileURL, andFormat: downloadList.fileData.format, andFileId: downloadList.fileData.id, andByte: downloadList.fileData.fileBytes))
    }
    
    func checkAllFilesCompleted() -> Bool {
        var completedCount = 0
        for tDl in arrFileDownloadData {
            if tDl.downloadComplete {
                completedCount = completedCount + 1
            }
        }
        if completedCount == arrFileDownloadData.count {
            return true
        }
        return false
    }
    
    func getTrackableFromTrackableDownload(_ trackableDl: CMSFileDownloadMeta?) -> ArtistFileData? {
        let trId = trackableDl?.fileId
        var index = 0
        for i in 0..<downloadListArray.count {
            let fdi = downloadListArray[i]
            if fdi.fileData.id! == trId! {
                index = i
                break
            }
        }
        return downloadListArray[index]
    }
    
    func getFileDownloadMetaIndex(withTaskIdentifier taskIdentifier: Int) -> Int {
        var index = 0
        for i in 0..<arrFileDownloadData.count {
            let fdi = arrFileDownloadData[i]
            if fdi.taskIdentifier == taskIdentifier {
                index = i
                break
            }
        }
        return index
    }
    
    func setTrackableCompleted(_ trackable: CMSFileDownloadMeta?) {
        let trackable = getTrackableFromTrackableDownload(trackable)
        let completionDirectory = CMSContentManagement.getFileDirectory(fromID: trackable?.fileData.id, withFormat: trackable?.fileData.format)
        CMSContentManagement.writeCompletedFile(toDirectory: completionDirectory)
    }
    
    func updateDownloadCompleteList() -> [ArtistFileData] {
        let localArtisFileData = CMSLoadDataFromFiles.getLocalArtistFileData()
        var completeList:[ArtistFileData] = localArtisFileData
        for downloadList in downloadListArray {
            completeList = localArtisFileData.filter({ (localFile) -> Bool in
                return !(downloadList.artistID == localFile.artistID && downloadList.fileData.id == localFile.fileData.id && downloadList.fileData.format == localFile.fileData.format && downloadList.fileData.checksum != localFile.fileData.checksum)
            })
        }
        for downloadList in downloadListArray {
            completeList.append(downloadList)
        }
        return completeList
    }
    
    func isConnectedToInternet() -> Bool {
        do {
            if try Reachability().connection == .unavailable {
                return false
            }
            return true
        } catch {
            return true
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let error: Error? = nil
        let fileManager = FileManager.default
        print("didFinishDownloadingTo \(arrFileDownloadData)")
        let index = getFileDownloadMetaIndex(withTaskIdentifier: downloadTask.taskIdentifier)
        if arrFileDownloadData.count > 0 {
            let fileDownloadInfo = arrFileDownloadData[index]
            let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let bundleRoot = paths.first
            if let uwBundleRoot = bundleRoot {
                let dataPath2 = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent("Assets/\(fileDownloadInfo.fileFormat!)/\(fileDownloadInfo.fileId!)").relativePath
                if !FileManager.default.fileExists(atPath: dataPath2) {
                    do {
                        try FileManager.default.createDirectory(atPath: dataPath2, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                } else {
                    CMSContentManagement.cleanTrackableFileDirectory(getTrackableFromTrackableDownload(fileDownloadInfo))
                }
                let destinationDir = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent("Assets/\(fileDownloadInfo.fileFormat!)/\(fileDownloadInfo.fileId!)/\(fileDownloadInfo.fileTitle!)").relativePath
                if fileManager.fileExists(atPath: destinationDir) {
                    do {
                        try fileManager.removeItem(atPath: destinationDir)
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                let destinationURL = URL(fileURLWithPath: destinationDir)
                
                var success = false
                do {
                    try fileManager.copyItem(at: location, to: destinationURL)
                    success = true
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                
                // If file has been copied to the directory location successfully
                if success {
                    print("\(String(describing: downloadTask.response)) file has been copied to the directory location successfully ")
                    fileDownloadInfo.isDownloading = false
                    fileDownloadInfo.downloadComplete = true
                    fileDownloadInfo.taskIdentifier = -1
                    fileDownloadInfo.taskResumeData = nil
                    self.setTrackableCompleted(fileDownloadInfo)
                } else {
                    if let uwError = error {
                        print("Unable to copy temp file. Error: \(uwError.localizedDescription)")
                    }
                }
                
            }
        } else {
            print("didFinishDownloadingTo arrFileDownloadData no value")
            session.invalidateAndCancel()
        }
        
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown {
            // Locate the FileDownloadInfo object among all based on the taskIdentifier property of the task.
            print("didWriteData \(arrFileDownloadData)")
            let index = getFileDownloadMetaIndex(withTaskIdentifier: downloadTask.taskIdentifier)
            if arrFileDownloadData.count > 0 {
                let fdi = arrFileDownloadData[index]
                fdi.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                print("downloadProgress:\(fdi.downloadProgress) totalBytesWritten:\(totalBytesWritten) bytesWritten:\(bytesWritten)")
            } else {
                print("didWriteData arrFileDownloadData no value")
                session.invalidateAndCancel()
            }
            
        } else {
//            print("NSURLSessionTransferSizeUnknown : \(totalBytesExpectedToWrite)")
            let index = getFileDownloadMetaIndex(withTaskIdentifier: downloadTask.taskIdentifier)
            if arrFileDownloadData.count > 0 {
                let fdi = arrFileDownloadData[index]
                fdi.downloadProgress = Double(totalBytesWritten) / Double(fdi.fileByte!)
                print("downloadProgress:\(fdi.downloadProgress) totalBytesWritten:\(totalBytesWritten) bytesWritten:\(bytesWritten)")
            } else {
                print("didWriteData arrFileDownloadData no value")
                session.invalidateAndCancel()
            }
        }
    }
}
