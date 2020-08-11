//
//  ViewController.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 21/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit
import KudanAR

struct DetectTutorial {
    static let keyforTutorial = "validateTutorial"
    static var isFirst: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyforTutorial)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyforTutorial)
        }
    }
}

struct ValidateCellular {
    static let key = "validateCellular"
    static var allowed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

enum ARViewMode {
    case scan
    case detected
}

enum ContentType: String {
    case url = "url"
    case stamp = "stamp"
    case threedcg = "3dcg"
    case unknown = "unknown"
    
    init(fromRawValue: String){
        self = ContentType(rawValue: fromRawValue) ?? .unknown
    }
}

public class EMTGARViewController: ARCameraViewController {
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var downloadView: UIImageView?
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    @IBOutlet weak var arFrame: UIImageView!
    @IBOutlet weak var scanView: UIImageView!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var closeShareBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var shareImageView: UIImageView!
    @IBOutlet weak var stickersView: UIView!
    @IBOutlet weak var bgStickerImageView: UIImageView!
    @IBOutlet weak var menuBtn: UIButton!
    
    var appContent: CMSContentManagement?
    var trackableDictionary: [AnyHashable : Any]?
    var contentDictionary: [AnyHashable : Any?]?
    var arrTrackableArray: [ArtistFileData]?
    var arrContentFileArray: [ArtistFileData]?
    var markerInfo: MarkersInfo?
    var openHistory:Bool = false
    var history:History?
    var presentURL:Bool = false
    var playScanAnimate:Bool = false
    var enableTrack:Bool = true
    var stickerArray: [UIImage] = []
    var currentTracking:ARImageTrackable?
    var viewMode:ARViewMode = .scan
    var contentType:ContentType = .unknown
    var fullScreenNode:ARNode?
    var saveFlag:Bool = true
    var modelUnitScale: Float = 0
    private var _selectedStickerView:StickerView?
    var selectedStickerView:StickerView? {
        get {
            return _selectedStickerView
        }
        set {
            
            // if other sticker choosed then resign the handler
            if _selectedStickerView != newValue {
                if let selectedStickerView = _selectedStickerView {
                    selectedStickerView.showEditingHandlers = false
                }
                _selectedStickerView = newValue
            }
            
            // assign handler to new sticker added
            if let selectedStickerView = _selectedStickerView {
                selectedStickerView.showEditingHandlers = true
                selectedStickerView.superview?.bringSubviewToFront(selectedStickerView)
            }
        }
    }
    
    var menuDelegate: MemuControllerDelegate?
    // MARK: - IBAction
    @IBAction func ibaCloseBtn(_ sender: Any) {
        menuDelegate?.didCloseAR(selected: "imageAR")
        //        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func ibaCameraBtn(_ sender: Any) {
        DispatchQueue.main.async {
            self.cameraBtn.isMultipleTouchEnabled = false
            let image = self.cameraView.contentViewPort.renderTarget.screenshot()
            if self.viewMode == .detected && self.contentType == .stamp {
                self.bgStickerImageView.isHidden = false
                self.bgStickerImageView.image = image
                let stickersImage = UtilityFunctions.image(with: self.stickersView)
                self.bgStickerImageView.isHidden = true
                self.bgStickerImageView.image = nil
                ARPhotoAlbum.shared.save(image: stickersImage!) { (success) in
                    DispatchQueue.main.async {
                        self.cameraBtn.isMultipleTouchEnabled = true
                        if success {
                            self.shareView.isHidden = false
                            self.shareImageView.image = stickersImage
                        }
                    }
                }
            }
            else {
                if let uwImage = image {
                    ARPhotoAlbum.shared.save(image: uwImage) { (success) in
                        DispatchQueue.main.async {
                            self.cameraBtn.isMultipleTouchEnabled = true
                            if success {
                                self.shareView.isHidden = false
                                self.shareImageView.image = uwImage
                            }
                        }
                    }
                    
                }
            }
            
        }
        
    }
    
    @IBAction func ibaCloseShareBtn(_ sender: Any) {
        self.shareView.isHidden = true
    }
    
    @IBAction func ibaShareBtn(_ sender: Any) {
        let imageShare = [ self.shareImageView.image ]
        let activityViewController = UIActivityViewController(activityItems: imageShare as [Any] , applicationActivities: nil)
        DispatchQueue.main.async {
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func tapSticker(
        _ sender: Any) {
        self.selectedStickerView?.showEditingHandlers = false
    }
    
    @IBAction func ibaBackBtn(_ sender: Any) {
        if contentType == .stamp {
            let stickerViewArray = self.stickersView.subviews.filter{$0 is StickerView}
            for stickerView in stickerViewArray {
                stickerView.removeFromSuperview()
            }
            
        }
        if contentType == .threedcg {
            for node in self.cameraView.contentViewPort.camera.children {
                if node == fullScreenNode {
                    self.cameraView.contentViewPort.camera.removeChild(node)
                    for children in node.children {
                        currentTracking!.world.addChild(children)
                    }
                    node.remove()
                }
            }
            currentTracking?.world.removeAllChildren()
        }
        displayARScanView()
        viewMode = .scan
        if !saveFlag {
            currentTracking = nil
            guard let _arrContentFileArray = arrContentFileArray else {return}
            for contentFile in _arrContentFileArray {
                if let format = contentFile.fileData.format {
                    if format != "thumbnail" {
                        CMSContentManagement.cleanTrackableFileDirectory(contentFile)
                    }
                }
            }
        }
    }
    
    @IBAction func ibaMenuBtn(_ sender: Any) {
        menuDelegate?.handleMenuToggle()
    }
    
    //MARK: - Setup FileData
    public override func viewDidLoad() {
        DispatchQueue.main.async {
            var loadingImages:[UIImage] = []
            for index in 0...8 {
                let frameworkBundle = Bundle().emtgarResourceBundle
                if let image = UIImage(named: "app_loading_anim_\(index)", in: frameworkBundle, compatibleWith: nil) {
                    loadingImages.append(image)
                }
            }
            self.downloadView?.animationImages = loadingImages
            self.downloadView?.animationDuration = 1.0
            self.setSplashScreenShow()
        }
        
    }
    
    public override func setupContent() {
        DispatchQueue.main.async {
            self.setSplashScreenHidden()
            if self.checkCellularAllowed() {
                self.getTrackables()
            } else {
                self.showCellularDownloadAlert()
            }
//            if !DetectTutorial.isFirst {
//                DispatchQueue.main.async {
//                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "TutorialViewController") as! TutorialViewController
//                    vc.modalPresentationStyle = .overFullScreen
//                    vc.tutorialDelegate = self
//                    self.present(vc, animated: false, completion: nil)
//                }
//            }
        }
        
    }
    
    deinit {
        //        if appContent != nil {
        //            appContent = nil
        //        }
        //        if _selectedStickerView != nil {
        //            _selectedStickerView = nil
        //        }
        //        if selectedStickerView != nil {
        //            selectedStickerView = nil
        //        }
        //        if fullScreenNode != nil {
        //            fullScreenNode = nil
        //        }
        //        if menuDelegate != nil {
        //            menuDelegate = nil
        //        }
        
        print("EMTGARViewController deinit")
    }
    
    func getTrackables() {
        appContent = CMSContentManagement()
        appContent?.downloadTask = CMSNetworking()
        appContent?.downloadTask?.getJSONFileMarkerDataFromURL(completionHandler: {[weak self] (success) in
            if success {
                self?.appContent?.downloadTask?.progressDelegate = self
                self?.trackableDictionary = self?.appContent?.getTrackables()
                self?.arrTrackableArray = self?.trackableDictionary?["Trackables"] as? [ArtistFileData]
                if !((self?.trackableDictionary?["InternetConncection"] as? Bool ?? false)) {
                    self?.showLackOfConnectivityAlert()
                }
                self?.setupTrackers()
            }
        })
        
    }
    
    func getContentFile(_ trackable: ARImageTrackable) {
        contentDictionary = appContent?.getContentFile(trackable.name)
        arrContentFileArray = contentDictionary?["ContentFile"] as? [ArtistFileData]
        markerInfo = contentDictionary?["MarkerInfo"] as? MarkersInfo
        if let _saveflag = markerInfo?.contentInfo?.saveFlag {
            self.saveFlag = _saveflag
        }
        if !((contentDictionary?["InternetConncection"] as? Bool ?? false)) {
            showLackOfConnectivityAlert()
        } else {
            guard let endDateString = markerInfo?.end else { return }
            print(endDateString)
            guard let endDate = dateByString(stringDate: endDateString) else { return }
            if endDate > Date() {
                if let memberStatusID = markerInfo?.conditions?.memberStatusID {
                    appContent?.downloadTask?.getMemberStatus(memberStatusID: memberStatusID, cid: markerInfo?.conditions?.cid, completionHandler: {[weak self] (status) in
                        if status == 1 {
                            self?.currentTracking = trackable
                            self?.playImageTrackable(trackable)
                        }
                        else {
                            self?.viewMode = .scan
                        }
                    })
                }
            } else {
                if openHistory {
                    removeARImageTrackFromHistory(trackable)
                }
            }
        }
    }
    
    func checkCellularAllowed() -> Bool {
        if UtilityFunctions.isConnectedToCellular() {
            if ValidateCellular.allowed {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func configuretionNavigationBar() {
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.barStyle = .default
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(handleMenuToggle))
    }
    
    @objc func handleMenuToggle() {
        
    }
    
    // MARK: - AR
    /// Adds trackables to the tracker manager
    func setupTrackers() {
        let trackerManager = ARImageTrackerManager.getInstance()
        trackerManager?.initialise()
        let karmarkerArray = arrTrackableArray?.filter({ (data) -> Bool in
            return (data.fileData.format! == "karmarker")
        })
        if let uwKarmarkerArray = karmarkerArray {
            for trackable in uwKarmarkerArray {
                if trackable.fileData.fileComplete {
                    setupTrackableSet(trackable.fileData)
                }
            }
        }
        
        if openHistory {
            guard let trackableName = history?.trackableName else { return }
            let trackerManager = ARImageTrackerManager.getInstance()
            let imageTrackable = trackerManager?.findTrackable(byName: trackableName)
            if let uwImageTrackable = imageTrackable {
                historyTracking(uwImageTrackable)
            }
        }
        
    }
    
    func setupTrackableSet(_ cmsTrackable: FileData?) {
        let trackerManager = ARImageTrackerManager.getInstance()
        trackerManager?.initialise()
        if !(FileManager.default.fileExists(atPath: cmsTrackable?.filePath ?? "")) {
            print("Local files have been removed")
        } else {
            let trackableSet = ARImageTrackableSet(path: cmsTrackable?.filePath)
            guard let uwTrackableSet = trackableSet else { return }
            for trackable in uwTrackableSet.trackables {
                if let arImgTrackable = trackable as? ARImageTrackable{
                    if let tId = cmsTrackable?.id {
                        arImgTrackable.name = "\(arImgTrackable.name!)artisId\(tId)"
                    }
                    arImgTrackable.addTrackingEventTarget(self, action: #selector(textTracking(_:)), forEvent: ARImageTrackableEventDetected)
                    arImgTrackable.addTrackingEventTarget(self, action: #selector(textLost(_:)), forEvent: ARImageTrackableEventLost)
                    trackerManager?.addTrackable(arImgTrackable)
                }
                
            }
        }
    }
    
    @objc func textTracking(_ trackable: ARImageTrackable) {
        if enableTrack {
            if viewMode == .scan {
                viewMode = .detected
                openHistory = false
                checkNewTrackable(trackable)
            } else {
                if contentType == .threedcg && currentTracking == trackable {
                    for node in self.cameraView.contentViewPort.camera.children {
                        if node == fullScreenNode {
                            self.cameraView.contentViewPort.camera.removeChild(node)
                            for children in node.children {
                                currentTracking!.world.addChild(children)
                            }
                            node.remove()
                        }
                    }
                }
            }
        }
    }
    
    func historyTracking(_ trackable: ARImageTrackable) {
        if viewMode == .scan {
            viewMode = .detected
            checkNewTrackable(trackable)
            
        } else {
            if contentType == .threedcg {
                for node in self.cameraView.contentViewPort.camera.children {
                    if node == fullScreenNode {
                        self.cameraView.contentViewPort.camera.removeChild(node)
                        for children in node.children {
                            currentTracking!.world.addChild(children)
                        }
                        node.remove()
                    }
                }
            }
        }
        
    }
    
    func playImageTrackable(_ trackable: ARImageTrackable) {
        contentType = self.checkContentType(trackable: trackable)
        switch contentType {
        case .url:
            if (!presentURL) {
                if(setupContentTypeURL(trackable)) {
                    presentURL = true
                    if !self.openHistory {
                        self.updateJsonHistory(trackable)
                    }
                } else {
                    self.viewMode = .scan
                    print("setup content url fail!")
                }
            }
        case .stamp:
            DispatchQueue.main.async(execute: {
                if(self.setupContentTypeStamp(trackable)) {
                    self.displayARDetectedView()
                    if !self.openHistory {
                        self.updateJsonHistory(trackable)
                    }
                } else {
                    print("setup content stamp fail!")
                    self.viewMode = .scan
                }
            })
        case .threedcg:
            DispatchQueue.main.async(execute: {
                for node in self.cameraView.contentViewPort.camera.children {
                    if node == self.fullScreenNode {
                        self.cameraView.contentViewPort.camera.removeChild(node)
                        for children in node.children {
                            self.currentTracking!.world.addChild(children)
                        }
                        node.remove()
                    }
                }
                if trackable.world.children.count == 0 {
                    if(self.setupContentType3dcg(trackable)) {
                        self.displayARDetectedView()
                        if !self.openHistory {
                            self.updateJsonHistory(trackable)
                        } else {
                            self.setup3dcgFullscreen(trackable)
                        }
                    } else {
                        print("setup content 3dcg fail!")
                        self.viewMode = .scan
                    }
                } else {
                    self.displayARDetectedView()
                    if !self.openHistory {
                        self.updateJsonHistory(trackable)
                    }
                }
            })
        default:
            viewMode = .scan
            print("unknow content Type")
        }
    }
    
    @objc func textLost(_ trackable: ARImageTrackable) {
        if contentType == .threedcg && viewMode == .detected && currentTracking == trackable {
            setup3dcgFullscreen(trackable)
        }
    }
    
    func checkNewTrackable(_ trackable: ARImageTrackable) {
        if currentTracking != trackable {
            getContentFile(trackable)
        } else {
            playImageTrackable(trackable)
        }
    }
    
    func checkContentType(trackable: ARImageTrackable) -> ContentType {
        guard let contentInfo = markerInfo?.contentInfo else {return .unknown}
        guard let type = contentInfo.type else {return .unknown}
        contentType = ContentType.init(fromRawValue: type)
        return contentType
    }
    
    func setupContentTypeURL(_ trackable: ARImageTrackable) -> Bool {
        let fileData = arrContentFileArray?.first(where: { (data) -> Bool in
            return data.fileData.format == "content"
        })
        guard let uwFileData = fileData else { return false}
        let sourceURL = URL(fileURLWithPath: uwFileData.fileData.filePath!)
        do {
            let urlTxt = try String(contentsOf: sourceURL, encoding: .utf8)
            DispatchQueue.main.async(execute: {
                let contentInfo = self.markerInfo?.contentInfo
                let contentName = contentInfo?.contentName
                
                let alert = UIAlertController(title: "", message: "\(contentName!) に遷移します。よろしいですか？", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "はい", style: .default, handler: { action in
                    guard let url = URL(string: urlTxt) else { return }
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                    self.viewMode = .scan
                    self.presentURL = false
                })
                let cancelButton = UIAlertAction(title: "いいえ", style: .cancel, handler: { action in
                    self.viewMode = .scan
                    self.presentURL = false
                })
                alert.addAction(cancelButton)
                alert.addAction(okButton)
                self.present(alert, animated: true)
                
            })
        }
        catch {
            return false
        }
        return true
    }
    
    func setupContentTypeStamp(_ trackable: ARImageTrackable) -> Bool {
        self.stickerArray.removeAll()
        let fileData = arrContentFileArray?.first(where: { (data) -> Bool in
            return data.fileData.format! == "content"
        })
        guard let uwFileData = fileData else { return false}
//        let stampPath = "\(uwFileData.fileData.format!)/\(uwFileData.fileData.id!)/stamp"
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        if let uwBundleRoot = bundleRoot {
            let sourceURL = URL(fileURLWithPath: uwFileData.fileData.filePath!)
            let destinationURL = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent("Assets/\(uwFileData.fileData.format!)/\(uwFileData.fileData.id!)/stamp")
            if FileManager.default.fileExists(atPath: destinationURL.relativePath) {
                do {
                    try FileManager.default.removeItem(atPath: destinationURL.relativePath)
                } catch {
                    print("remove error \(error.localizedDescription )")
                }
            }
            do {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                try fileManager.unzipItem(at: sourceURL, to: destinationURL)
            } catch {
                print("Extraction of ZIP archive failed with error:\(error)")
            }
        }
        if let uwBundleRoot = bundleRoot {
            let destinationURL = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent("Assets/\(uwFileData.fileData.format!)/\(uwFileData.fileData.id!)/stamp")
            let enumerator = FileManager.default.enumerator(atPath: destinationURL.path)
            let filePaths = enumerator?.allObjects as! [String]
            for filePath in filePaths {
                let pathURL = URL(fileURLWithPath: destinationURL.path).appendingPathComponent(filePath)
                do {
                    let imageData = try Data(contentsOf: pathURL)
                    if let imageStamp = UIImage(data: imageData) {
                        self.stickerArray.append(imageStamp)
                    }
                } catch {
                    print(error)
                }
                
            }
        } else {
            return false
        }
        
        var itemList: [UIImage?] = []
        if stickerArray.count > 5 {
            for _ in 1...5 {
                let item = stickerArray.randomElement()
                itemList.append(item)
            }
        } else {
            itemList = stickerArray
        }
        
        for (index, sticker) in itemList.enumerated() {
            DispatchQueue.main.async(execute: {
                let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 150, height: 150))
                imageView.contentMode  = .scaleAspectFit
                imageView.image = sticker
                
                let stickerView = StickerView.init(contentView: imageView)
                stickerView.center = CGPoint(x: self.stickersView.center.x, y: self.stickersView.center.y)
                stickerView.delegate = self
                stickerView.showEditingHandlers = false
                stickerView.tag = index
                self.stickersView.addSubview(stickerView)
                if sticker == self.stickerArray.last {
                    self.selectedStickerView = stickerView
                }
            })
        }
        return true
    }
    
    func setupContentType3dcg(_ trackable: ARImageTrackable) -> Bool {
        print("setupContentType3dcg")
        var modelXUnit: Float = 26
        var modelYUnit: Float = 26
        var modelZUnit: Float = 4
        let trackerManager = ARImageTrackerManager.getInstance()
        let imageTrackable = trackerManager?.findTrackable(byName: trackable.name)
        guard let uwImageTrackable = imageTrackable else { return false}
        uwImageTrackable.world.removeAllChildren()
        let contentArray = arrContentFileArray?.filter({ (data) -> Bool in
            return data.fileData.format! == "content"
        })
        guard let uwContentArray = contentArray else { return false}
        var modelPath = ""
        var texturePath = ""
        var videoPath = ""
        for content in uwContentArray {
            if (content.fileData.filedataExtension == "armodel") {
                modelPath = content.fileData.filePath!
                if let unitSize = content.fileData.unitSize {
                    modelXUnit = Float(unitSize.x ?? 26)
                    modelYUnit = Float(unitSize.y ?? 26)
                    modelZUnit = Float(unitSize.z ?? 4)
                }
            }
            if (content.fileData.filedataExtension == "png" || content.fileData.filedataExtension == "jpeg") {
                texturePath = content.fileData.filePath!
            }
            if (content.fileData.filedataExtension == "mp4") {
                videoPath = content.fileData.filePath!
            }
        }
        
        // Import the model.
        let importer = ARModelImporter(path: modelPath)
        // Get a node representing the model's contents.
        guard let uwImporter = importer else { return false}
        let modelNode = uwImporter.getNode()
        // Create the model texture from a UIImage.
        let imageTexture = UIImage(contentsOfFile: texturePath)
        let modelTexture = ARTexture(uiImage: imageTexture)
        // Create a textured material using the texture.
        let textureMaterial = ARTextureMaterial(texture: modelTexture)
        // Assign textureMaterial to every mesh in the model.
        guard let uwModelNode = modelNode else { return false}
        if let meshNodes = uwModelNode.meshNodes {
            for meshNode in meshNodes {
                guard let meshNode = meshNode as? ARMeshNode else {
                    continue
                }
                meshNode.material = textureMaterial
            }
        }
        
        if modelXUnit < modelYUnit {
            modelUnitScale = Float(trackable.width) / modelYUnit
        } else {
            modelUnitScale = Float(trackable.height) / modelXUnit
        }
        // Modelled with y-axis up. Marker has z-axis up. Rotate around the x-axis to correct this.
        modelNode?.rotate(byDegrees: 90, axisX: 1, y: 0, z: 0)
        let position = ARVector3.init(valuesX: 0, y: 0, z: 0)
        modelNode?.position = position
        modelNode?.scale(byUniform: modelUnitScale)
        // Add the model to a marker.
        let videoNode = ARAlphaVideoNode(bundledFile: videoPath)
        guard let uwVideoNode = videoNode else { return false}
        
        var videoScale: Float = 0
        var videoPositionZ: Float = 0
        if modelXUnit < modelYUnit {
            videoScale = (Float(trackable.width) / Float(uwVideoNode.videoTexture.width))/2
        } else {
            videoScale = (Float(trackable.height) / Float(uwVideoNode.videoTexture.height))/2
        }
        uwVideoNode.rotate(byDegrees: 90, axisX: 1, y: 0, z: 0)
        videoPositionZ = ((Float(uwVideoNode.videoTexture.height) * videoScale) / 2.0) + (modelUnitScale * (modelZUnit + 1))
        let positionVideo = ARVector3.init(valuesX: 0, y: 0, z: videoPositionZ)
        uwVideoNode.position = positionVideo
        uwVideoNode.scale(byUniform: videoScale)
        uwVideoNode.videoTexture.play()
        uwVideoNode.videoTexture.resetThreshold = 2
        
        uwImageTrackable.world.addChild(uwVideoNode)
        uwImageTrackable.world.addChild(uwModelNode)
        return true
    }
    
    func setup3dcgFullscreen(_ trackable: ARImageTrackable){
        let trackerManager = ARImageTrackerManager.getInstance()
        let imageTrackable = trackerManager?.findTrackable(byName: trackable.name)
        guard let uwImageTrackable = imageTrackable else { return }
        if uwImageTrackable.world.children.count != 0 {
            fullScreenNode = ARNode(name: "fullscreen")
            for node in uwImageTrackable.world.children {
                fullScreenNode?.addChild(node)
            }
            self.cameraView.contentViewPort.camera.addChild(fullScreenNode)
//            var scaleFit:Float = Float(uwImageTrackable.height)
//            if uwImageTrackable.width < uwImageTrackable.height {
//                scaleFit = Float(uwImageTrackable.width)
//            }
//                        if self.cameraView.contentViewPort.width > scaleFit {
//                            scaleFit = self.cameraView.contentViewPort.width/scaleFit
//                        } else {
//                            scaleFit = scaleFit/self.cameraView.contentViewPort.width
//                        }
//                        print("scaleFit\(scaleFit) cameraView width \(self.cameraView.contentViewPort.width)")
            
            var scaleFit:Float  = self.cameraView.contentViewPort.width / Float(trackable.width)
            
        
            
            print("fullScreenNode scaleFit \(scaleFit) \(modelUnitScale) \(Float(trackable.width)) \(Float(trackable.height))")
            fullScreenNode?.position = ARVector3(valuesX: -200, y: -8, z: -1000)
            fullScreenNode?.rotate(byDegrees: 90, axisX: 1, y: 0, z: 0)
            fullScreenNode?.rotate(byDegrees: 90, axisX: 0, y: 1, z: 0)
            fullScreenNode?.scale(byUniform:20/modelUnitScale)
        }
    }
    
    //MARK: - Update History
    
    func setContentHistory(_ trackable: ARImageTrackable) -> History {
        let contentInfo = markerInfo?.contentInfo
        let name = markerInfo?.name
        let detail = contentInfo?.contentName
        let thumbnail = arrContentFileArray?.first(where: { (data) -> Bool in
            return data.fileData.format! == "thumbnail"
        })
        let endDate = markerInfo?.end
        let pathComponent = "Assets/\(thumbnail!.fileData.format!)/\(thumbnail!.fileData.id!)/\(thumbnail!.fileData.fileName!)"
        return History(arImageTrackable: trackable.name, andTitle: name!, andDetail: detail!, andPathComponent: pathComponent, andEndDate: endDate!, andScanDate: stringDate(date: Date()), date: Date())
    }
    
    func updateJsonHistory(_ trackable: ARImageTrackable) {
        let historyArray = CMSLoadDataFromFiles.getJsonHistory()
        if historyArray.count != 0 {
            let contentHistory = historyArray.first { (history) -> Bool in
                return history.trackableName == trackable.name
            }
            if contentHistory != nil {
                let updateHistory = historyArray.map { (history) -> History in
                    var updateHistory = history
                    if updateHistory.trackableName == trackable.name {
                        updateHistory.scanDate = stringDate(date: Date())
                        updateHistory.date = Date()
                    }
                    return updateHistory
                }
                CMSLoadDataFromFiles.saveJsonHistory(historyArray: updateHistory)
            } else {
                var updateHistory:[History] = historyArray
                updateHistory.append(setContentHistory(trackable))
                CMSLoadDataFromFiles.saveJsonHistory(historyArray: updateHistory)
            }
        } else {
            var updateHistory:[History] = []
            updateHistory.append(setContentHistory(trackable))
            CMSLoadDataFromFiles.saveJsonHistory(historyArray: updateHistory)
        }
    }
    
    func removeARImageTrackFromHistory(_ trackable: ARImageTrackable) {
        let historyArray = CMSLoadDataFromFiles.getJsonHistory()
        if historyArray.count != 0 {
            let contentHistory = historyArray.filter { (history) -> Bool in
                return history.trackableName != trackable.name
            }
            CMSLoadDataFromFiles.saveJsonHistory(historyArray: contentHistory)
        }
    }
    
    
    func stringDate(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    func dateByString(stringDate:String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: stringDate)
    }
    
    // MARK: - ViewManagement
    
    func animateSencerView() {
        
        DispatchQueue.main.async(execute: {
            if self.scanView != nil {
                self.scanView.layer.removeAllAnimations()
                self.scanView.frame = CGRect(x: 0, y: self.view.frame.height + self.scanView.frame.height, width: self.scanView.frame.width, height: self.scanView.frame.height)
                UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
                    self.scanView.frame = CGRect(x: 0, y: -self.scanView.frame.height, width: self.scanView.frame.width, height: self.scanView.frame.height)
                }) { (completed) in
                    if self.scanView != nil {
                        self.scanView.transform = CGAffineTransform(scaleX: 1, y: -1)
                        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
                            self.scanView.frame = CGRect(x: 0, y: self.view.frame.height + self.scanView.frame.height, width: self.scanView.frame.width, height: self.scanView.frame.height)
                        }) { (completed) in
                            if self.scanView != nil {
                                self.scanView.transform = CGAffineTransform(scaleX: 1, y: 1)
                                if self.playScanAnimate {
                                    self.animateSencerView()
                                }
                            }
                        }
                    }
                }
            }
        })
        
    }
    
    func setDownloadProgressHidden() {
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.1, animations: {
                self.downloadView?.alpha = 0.0
                self.downloadView?.stopAnimating()
            })
        })
    }
    
    func setDownloadProgressShow() {
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.1, animations: {
                self.downloadView?.alpha = 1.0
                self.downloadView?.startAnimating()
            })
        })
    }
    
    func setSplashScreenHidden() {
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.1, animations: {
                self.closeBtn.alpha = 1.0
                self.setDownloadProgressHidden()
            })
        })
        self.displayARScanView()
    }
    
    func setSplashScreenShow() {
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.1, animations: {
                self.setDownloadProgressShow()
            })
        })
    }
    
    func setARFunctionHidden() {
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.1, animations: {
                self.arFrame.alpha = 0.0
                self.closeBtn.alpha = 0.0
                self.cameraBtn.alpha = 0.0
                self.menuBtn.alpha = 0
            })
        })
        
    }
    
    func displayARScanView() {
        DispatchQueue.main.async(execute: {
            self.scanView.alpha = 1.0
            self.animateSencerView()
            self.playScanAnimate = true
            UIView.animate(withDuration: 0.1, animations: {
                self.arFrame.alpha = 1.0
                self.backBtn.alpha = 0
                self.cameraBtn.alpha = 0
                self.menuBtn.alpha = 1.0
                self.closeBtn.alpha = 1.0
            })
        })
    }
    
    func displayARDetectedView() {
        DispatchQueue.main.async(execute: {
            self.scanView.alpha = 0.0
            self.playScanAnimate = false
            UIView.animate(withDuration: 0.1, animations: {
                self.menuBtn.alpha = 0
                self.arFrame.alpha = 0
                self.backBtn.alpha = 1.0
                self.cameraBtn.alpha = 1.0
                self.closeBtn.alpha = 0
            })
        })
        
    }
    
    func showLackOfConnectivityAlert() {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: "No network connection", message: "Please connect to the internet to download new markers", preferredStyle: .alert)
            
            let okButton = UIAlertAction(title: "OK", style: .default, handler: { action in
                //Handle your yes please button action here
            })
            
            alert.addAction(okButton)
            
            self.present(alert, animated: true)
        })
        
    }
    
    func showCellularDownloadAlert(_ trackable: ARImageTrackable? = nil) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: "3G/4Gモバイルデータ通信時、", message: "メディアをダウンロードする際に\n確認メッセージを表示", preferredStyle: .alert)
            
            let okBtn = UIAlertAction(title: "OK", style: .default, handler: { action in
                if let _trackable = trackable {
                    self.getContentFile(_trackable)
                } else {
                    self.getTrackables()
                }
                ValidateCellular.allowed = true
            })
            
            let cancelBtn = UIAlertAction(title: "Cancel", style: .default) { (action) in
                
            }
            
            alert.addAction(okBtn)
            alert.addAction(cancelBtn)
            self.present(alert, animated: true)
        })
        
    }
    
    func showTotalFileDownload(totalFileSize:Int, _ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: "", message: "Please connect to the internet to download new markers", preferredStyle: .alert)
            
            let okBtn = UIAlertAction(title: "OK", style: .default, handler: { action in
                //Handle your yes please button action here
                completionHandler(true)
            })
            
            let cancelBtn = UIAlertAction(title: "Cancel", style: .default) { (action) in
                completionHandler(false)
            }
            
            alert.addAction(okBtn)
            alert.addAction(cancelBtn)
            
            self.present(alert, animated: true)
        })
        
    }
    
}
//MARK: - CMSDownloadProgress
extension EMTGARViewController: CMSDownloadProgress {
    func alertDownloadByCellular(fileByte: Int, _ completionHandler: @escaping (Bool) -> Void) {
        self.showTotalFileDownload(totalFileSize: fileByte) { (acceptDownload) in
            completionHandler(acceptDownload)
        }
    }
    
    func updateProgressView(_ percentage: NSNumber?) {
        //        DispatchQueue.main.async(execute: {
        //            let percentageValue:Float = percentage?.floatValue ?? 0.0
        //            self.downloadProgress.progress = percentageValue
        //        })
    }
    
    func startDownloadProgressView() {
        DispatchQueue.main.async(execute: {
            //            self.downloadProgress.progress = 0
            self.setDownloadProgressShow()
        })
    }
    
    func downloadFinishedLoadTrackable() {
        self.setDownloadProgressHidden()
    }
    
}

//MARK: - StickerViewDelegate

extension EMTGARViewController: StickerViewDelegate {
    func stickerViewDidBeginMoving(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidChangeMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidBeginRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidChangeRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidClose(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidTap(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    
}

extension EMTGARViewController: TutorialDelegate {
    func closeTutorial() {
        DetectTutorial.isFirst = true
    }
}
