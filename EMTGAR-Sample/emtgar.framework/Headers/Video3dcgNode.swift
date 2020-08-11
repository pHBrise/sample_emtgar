//
//  Video3dcgNode.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 19/5/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit
import KudanAR

class Video3dcgNode: ARNode {
//
//    init?(trackable:ARImageTrackable,_ fileData:[FileData]) {
//        super.init()
//        self.name = "video3dcg";
//        var modelPath = ""
//        var texturePath = ""
//        var videoPath = ""
//        for content in fileData {
//            if (content.fileExtension == "armodel") {
//                modelPath = content.filePath!
//            }
//            if (content.fileExtension == "png") {
//                texturePath = content.filePath!
//            }
//            if (content.fileExtension == "mp4") {
//                videoPath = content.filePath!
//            }
//        }
//
//        // Import the model.
//        let importer = ARModelImporter(path: modelPath)
//        // Get a node representing the model's contents.
//        guard let uwImporter = importer else { return nil}
//        let modelNode = uwImporter.getNode()
//        // Create the model texture from a UIImage.
//        let imageTexture = UIImage(contentsOfFile: texturePath)
//        let modelTexture = ARTexture(uiImage: imageTexture)
//        // Create a textured material using the texture.
//        let textureMaterial = ARTextureMaterial(texture: modelTexture)
//        // Assign textureMaterial to every mesh in the model.
//        guard let uwModelNode = modelNode else { return nil}
//        if let meshNodes = uwModelNode.meshNodes {
//            for meshNode in meshNodes {
//                guard let meshNode = meshNode as? ARMeshNode else {
//                    continue
//                }
//                meshNode.material = textureMaterial
//            }
//        }
//
//        let modelXUnit: Float = 26
//        let modelYUnit: Float = 26
//        let modelZUnit: Float = 4
//
//        var modelUnitScale: Float = 0
//        if modelXUnit < modelYUnit {
//            modelUnitScale = Float(trackable.width) / modelYUnit
//        } else {
//            modelUnitScale = Float(trackable.height) / modelXUnit
//        }
//        // Modelled with y-axis up. Marker has z-axis up. Rotate around the x-axis to correct this.
//        modelNode?.rotate(byDegrees: 90, axisX: 1, y: 0, z: 0)
//        let position = ARVector3.init(valuesX: 0, y: 0, z: 0)
//        modelNode?.position = position
//        modelNode?.scale(byUniform: modelUnitScale)
//        // Add the model to a marker.
//        let videoNode = ARAlphaVideoNode(bundledFile: videoPath)
//        guard let uwVideoNode = videoNode else { return nil}
//
//        var videoScale: Float = 0
//        var videoPositionZ: Float = 0
//        if modelXUnit < modelYUnit {
//            videoScale = (Float(trackable.width) / Float(uwVideoNode.videoTexture.width))/2
//        } else {
//            videoScale = (Float(trackable.height) / Float(uwVideoNode.videoTexture.height))/2
//        }
//        videoPositionZ = ((Float(uwVideoNode.videoTexture.height) * videoScale) / 2.0) + (modelUnitScale * (modelZUnit + 1))
//        uwVideoNode.rotate(byDegrees: 90, axisX: 1, y: 0, z: 0)
//        uwVideoNode.scale(byUniform: videoScale)
//        let positionVideo = ARVector3.init(valuesX: 0, y: 0, z: videoPositionZ)
//        uwVideoNode.position = positionVideo
//        uwVideoNode.videoTexture.play()
//        uwVideoNode.videoTexture.resetThreshold = 2
//
//        self.addChild(modelNode)
//        self.addChild(videoNode)
//    }

}
