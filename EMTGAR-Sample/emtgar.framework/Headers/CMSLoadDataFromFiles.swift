//
//  CMSLoadDataFromFiles.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 22/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation


class CMSLoadDataFromFiles: NSObject {
    
    var arrTrackables: [AnyHashable]?
    
    class func getTrackables() -> [ArtistFileData] {
        updateLocalHistory()
        var fileDataArray: [ArtistFileData] = []
        let localFileDataArray = getLocalFileMarkerDataArray(markerData: getLocalMarkerData())
        for localFileData in localFileDataArray {
            if self.fileDataIsSafe(toAdd: localFileData) {
                var tr = localFileData
                tr.fileData.fileComplete = true
                fileDataArray.append(tr)
            }
        }
        return fileDataArray
    }
    
    class func getContentFile(_ trackableName: String) -> [ArtistFileData] {
        var fileDataArray: [ArtistFileData] = []
        let localFileDataArray = getLocalFileMarkerDataArray(markerData: getLocalMarkerData(), trackName: trackableName)
        for localFileData in localFileDataArray {
            if self.fileDataIsSafe(toAdd: localFileData) {
                var tr = localFileData
                tr.fileData.fileComplete = true
                fileDataArray.append(tr)
            }
        }
        return fileDataArray
    }
    
    class func getContentMarkerInfo(_ trackableName: String) -> MarkersInfo? {
        var markerInfo:MarkersInfo?
        let markerData = getLocalMarkerData()
        let trackArray = trackableName.components(separatedBy: "artisId")
        guard let _contentInfo = trackArray.first, let _artisId = trackArray.last else { return markerInfo }
        guard let markerDetail = markerData?.details else {return markerInfo}
        guard let artistDataArray = markerDetail.artistData  else {return markerInfo}
        let artistDataFilter = artistDataArray.filter { (data) -> Bool in
            guard let artistId = data.artistID else {return false}
            return "\(artistId)" == _artisId
        }
        if artistDataFilter.count == 1 {
            guard let artistData = artistDataFilter.first else {return markerInfo}
            guard let markersInfoArray = artistData.markersInfo else {return markerInfo}

            let markersInfoFilter = markersInfoArray.filter { (markersInfo) -> Bool in
                return markersInfo.code == _contentInfo
            }
            if markersInfoFilter.count == 1 {
                markerInfo = markersInfoFilter.first
            }
        }
        
        return markerInfo
    }
    
    class func updateLocalHistory() {
        var updateHistory:[History] = []
        let jsonHistory = CMSLoadDataFromFiles.getJsonHistory()
        guard let markerData = getLocalMarkerData() else {return}
        guard let artistData = markerData.details?.artistData else {return}
        for artist in artistData {
            guard let artistID = artist.artistID else { return }
            guard let markersInfo = artist.markersInfo else { return }
            for info in markersInfo {
                guard let code = info.code, let name = info.name, let detail = info.contentInfo?.contentName, let endDate = info.end  else { return }
                let filterHistory = jsonHistory.filter({ (history) -> Bool in
                    return history.trackableName == "\(code)artisId\(artistID)"
                })
                let mapHistory = filterHistory.map { (history) -> History in
                    var updateHistory = history
                    if updateHistory.trackableName == "\(code)artisId\(artistID)" {
                        updateHistory.title = name
                        updateHistory.detail = detail
                        updateHistory.endDate = endDate
                    }
                    return updateHistory
                }
                if let history = mapHistory.first {
                    updateHistory.append(history)
                }
            }
        }
        print("updateHistory: \(updateHistory)")
        CMSLoadDataFromFiles.saveJsonHistory(historyArray: updateHistory)
    }
    
    class func getMarkerlessFile(_ artistFileData: ArtistFileData) -> ArtistFileData? {
        var fileDataArray:ArtistFileData?
        if self.fileDataIsSafe(toAdd: artistFileData) {
            var tr = artistFileData
            tr.fileData.fileComplete = true
            fileDataArray = tr
        }
        return fileDataArray
    }

    class func getLocalFileMarkerDataArray(markerData:MarkerData?,trackName:String? = nil) -> [ArtistFileData]  {
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
            print("contentFile \(temp )")
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
            print("markerfile \(temp )")
            return temp
        }
    }
    
    class func getLocalMarkerData() ->MarkerData? {
        var markerData:MarkerData?
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths[0]
        let jsonPath = URL(fileURLWithPath: bundleRoot).appendingPathComponent("JSON/markerdata.json").relativePath
        if FileManager.default.fileExists(atPath: jsonPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
                markerData = try JSONDecoder().decode(MarkerData.self, from: data)
                
            } catch {
                print("getLocalMarkerFileData error \(error)")
            }
        }
        return markerData
    }
    
    class func getLocalMarkerlessData() ->MarkerlessData? {
        var markerlessData:MarkerlessData?
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths[0]
        let jsonPath = URL(fileURLWithPath: bundleRoot).appendingPathComponent("JSON/markerlessdata.json").relativePath
        if FileManager.default.fileExists(atPath: jsonPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
                markerlessData = try JSONDecoder().decode(MarkerlessData.self, from: data)
                
            } catch {
                print("getLocalMarkerFileData error \(error)")
            }
        }
        return markerlessData
    }
    
    class func getLocalArtistFileData() -> [ArtistFileData] {
        var localFileDataArray:[ArtistFileData] = []
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths[0]
        let jsonPath = URL(fileURLWithPath: bundleRoot).appendingPathComponent("JSON/filedata.json").relativePath
        if FileManager.default.fileExists(atPath: jsonPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
                localFileDataArray = try JSONDecoder().decode([ArtistFileData].self, from: data)
            } catch {
                print("getLocalMarkerFileData error \(error)")
            }
        }
        return localFileDataArray
    }
    
    //MARK: - Update History
    class func saveJsonHistory(historyArray:[History]) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first
        if let uwDocumentsDirectory = documentsDirectory {
            let dataPath = URL(fileURLWithPath: uwDocumentsDirectory).appendingPathComponent("JSON/history.json")
            do {
                let Data = try? JSONEncoder().encode(historyArray)
                let pathAsURL = dataPath
                try Data?.write(to: pathAsURL)
            } catch {
                print(error)
            }
        }

    }
    
    class func getJsonHistory() -> [History] {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths[0]
        let jsonPath = URL(fileURLWithPath: bundleRoot).appendingPathComponent("JSON/history.json").relativePath
        if FileManager.default.fileExists(atPath: jsonPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
                let decoder = JSONDecoder()
                let allKeys = try decoder.decode([History].self, from: data)
                return allKeys
            } catch {
                print(error)
            }
        }
        return []
    }
    
    class func fileDataIsSafe(toAdd artistFileData: ArtistFileData?) -> Bool {
        guard let id = artistFileData?.fileData.id, let format = artistFileData?.fileData.format, let fileName = artistFileData?.fileData.fileName else {return false}
        let rootDirectory = CMSContentManagement.getFileDirectory(fromID: id, withFormat: format)
        if let uwRootDirectory = rootDirectory {
            let fileDataDirectory = URL(fileURLWithPath: uwRootDirectory).appendingPathComponent(fileName).relativePath
            let completedDirectory = URL(fileURLWithPath: uwRootDirectory).appendingPathComponent("completed.txt").relativePath
            if FileManager.default.fileExists(atPath: fileDataDirectory) && FileManager.default.fileExists(atPath: completedDirectory) {
                return true
            }
        }
        return false
    }

}
