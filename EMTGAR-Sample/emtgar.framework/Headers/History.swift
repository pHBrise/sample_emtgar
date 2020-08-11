//
//  History.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 27/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation
import KudanAR


class History: NSObject, Codable {
    var trackableName: String
    var title: String
    var detail: String
    var pathComponent: String
    var endDate: String
    var scanDate:String
    var date:Date
    init(arImageTrackable trackable: String, andTitle title: String, andDetail detail: String, andPathComponent pathComponent: String, andEndDate endDate: String, andScanDate scanDate: String, date:Date)  {
        self.trackableName = trackable
        self.title = title
        self.detail = detail
        self.pathComponent = pathComponent
        self.endDate = endDate
        self.scanDate = scanDate
        self.date = date
    }

}
