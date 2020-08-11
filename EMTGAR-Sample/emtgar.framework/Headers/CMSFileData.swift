//
//  CMSFileData.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import Foundation

struct ArtistFileData: Codable {
    var artistID: Int
    var fileData: FileData
    init(artistID: Int, fileData: FileData) {
        self.artistID = artistID
        self.fileData = fileData
    }
    
    static func == (lhs: ArtistFileData, rhs: ArtistFileData) -> Bool {
        return lhs.artistID == rhs.artistID && lhs.fileData.format == rhs.fileData.format && lhs.fileData.id == rhs.fileData.id
    }
}

struct FileData: Codable {
    let id: Int?
    let format, checksum: String?
    let fileBytes: Int?
    let fileName, filedataExtension: String?
    let unitSize: UnitSize?
    var filePath: String?
    var fileComplete:Bool = false
    enum CodingKeys: String, CodingKey {
        case id, format, checksum
        case fileBytes = "file_bytes"
        case fileName = "file_name"
        case filedataExtension = "extension"
        case unitSize = "unit_size"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        format = try values.decodeIfPresent(String.self, forKey: .format)
        checksum = try values.decodeIfPresent(String.self, forKey: .checksum)
        fileBytes = try values.decodeIfPresent(Int.self, forKey: .fileBytes)
        fileName = try values.decodeIfPresent(String.self, forKey: .fileName)
        filedataExtension = try values.decodeIfPresent(String.self, forKey: .filedataExtension)
        unitSize = try values.decodeIfPresent(UnitSize.self, forKey: .unitSize)
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        guard let _format = format, let _id = id, let _fileName = fileName else {return}
        filePath = URL(fileURLWithPath: bundleRoot ?? "").appendingPathComponent("Assets/\(_format)/\(_id)/\(_fileName)").relativePath
    }
}


// MARK: - UnitSize
struct UnitSize: Codable {
    let x, y, z: Int?
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        x = try values.decodeIfPresent(Int.self, forKey: .x)
        y = try values.decodeIfPresent(Int.self, forKey: .y)
        z = try values.decodeIfPresent(Int.self, forKey: .z)
    }
}
