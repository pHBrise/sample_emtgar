//
//  CMSFileDownloadMeta.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation

class CMSFileDownloadMeta: NSObject {
    var fileTitle: String?
    var fileId: Int?
    var fileByte: Int?
    var fileFormat: String?
    var downloadSource: String?
    var downloadTask: URLSessionDownloadTask?
    var taskResumeData: Data?
    var downloadProgress = 0.0
    var isDownloading = false
    var downloadComplete = false
    var taskIdentifier = 0

    init(fileTitle title: String?, andDownloadSource source: String?, andFormat fileFormat: String?, andFileId fileID: Int?, andByte fileByte: Int?) {
        self.fileTitle = title
        self.fileId = fileID
        self.fileByte = fileByte
        self.fileFormat = fileFormat
        self.downloadSource = source
        self.downloadProgress = 0.0
        self.isDownloading = false
        self.downloadComplete = false
        self.taskIdentifier = -1
    }
}
