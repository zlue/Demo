//
//  LueQRCodeConstroller.swift
//
//  Created by Luiz on 2018/8/1.
//  Copyright © 2018年 lue. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class LueQRCodeConstroller: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private lazy var session = AVCaptureSession()
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            debugPrint("设备输入获取失败#####")
            return nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            return input
        } catch {
            debugPrint("设备输入获取错误##### \(error)")
            return nil
        }
    }()
    private lazy var output = AVCaptureMetadataOutput()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.layer.bounds
        return layer
    }()
    
    private func startScan() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (b) in
                DispatchQueue.main.async {
                    self?.startScan()
                }
            }
        case .authorized:
            self.scan()
        default:
            self.deviceDisable()
        }
    }
    private func scan() {
        guard let input = deviceInput else {
            return
        }
        if !self.session.canAddInput(input) {
            return
        }
        if !self.session.canAddOutput(self.output) {
            return
        }
        self.session.addInput(input)
        self.session.addOutput(self.output)
        self.output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        self.output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        self.view.layer.insertSublayer(self.previewLayer, at: 0)
        self.session.startRunning()
        self.scanAimationView?.start()
    }
    
    private var scanAimationView: LueScanAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        navigationItem.title = LocalString("qr_code")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalString("album"), style: .done, target: self, action: #selector(selectAlbum))
        
        let w = view.bounds.width - 140
        let scanView = LueScanAnimationView(frame: CGRect(x: 70, y: 64 + 150, width: w, height: w), c: UIColor.blue)
        view.addSubview(scanView)
        self.scanAimationView = scanView
        
        let bgView = LueScanBgView(frame: view.bounds, inter: scanView.frame)
        view.addSubview(bgView)
        
        let hintLabel = UILabel()
        hintLabel.text = LocalString("scan_msg")
        hintLabel.font = UIFont.systemFont(ofSize: 15)
        hintLabel.textColor = UIColor.blue
        view.addSubview(hintLabel)
        hintLabel.sizeToFit()
        
        hintLabel.center = CGPoint(x: view.center.x, y: scanView.frame.maxY + hintLabel.frame.height)
    
        startScan()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    @objc private func willEnterForeground() {
        self.startScan()
    }
    
    @objc private func selectAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            PHPhotoLibrary.requestAuthorization { [weak self] (s) in
                DispatchQueue.main.async { [weak self] in
                    switch s {
                    case .authorized:
                        self?.imageChoiseType(type: 1)
                    default: self?.deviceDisable()
                    }
                }
            }
        }
    }
    func imageChoiseType(type: Int)  {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
        } else {
            showMessage("Albums can't be used.")
        }
        self.present(imagePicker, animated: true, completion: nil)
    }
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let img = info[.originalImage] as? UIImage, let ciImage = CIImage(image: img) else {
            return showMessage(LocalString("not_found"))
        }
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return showMessage(LocalString("not_found"))
        }
        guard let result = (detector.features(in: ciImage).first as? CIQRCodeFeature)?.messageString else {
            return showMessage(LocalString("not_found"))
        }
        resultHandle(result)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    // 设置 imagePicker 导航栏
//    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
//        navigationController.navigationBar.tintColor = UIColor.white
//        navigationController.navigationBar.barTintColor = UIColor.mainBg
//        navigationController.navigationBar.isTranslucent = false
//        navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.mainTt]
//    }

    
    var scanComplete: ((String) -> ())?
//    var assetScanSuccess: ((ETQRScanResultModel, String) -> ())?
    var browserScanComplete: ((String) -> ())?
    
    private var scanResult: String = ""
    private func resultHandle(_ result: String?) {
        self.session.stopRunning()
        self.previewLayer.removeFromSuperlayer()
        self.scanAimationView?.stop()
        
        if let str = result {
            if browserScanComplete == nil {
                scanSuccess(t: str)
            } else {
                self.navigationController?.popViewController(animated: true)
                browserScanComplete?(str)
            }
        } else {
            showMessage(LocalString("not_found"))
            self.navigationController?.popViewController(animated: true)
        }
    }
    private func scanSuccess(t: String) {
        scanResult = t
        LueHUD.showLoading()
//        let tt = LueCoder.jsonStringify(t) ?? ""
//        let fun = "getQrCodeAction(\"\(tt)\")"
//        LueWebView.share.evaluate(js: fun) { (a, r) in }
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func deviceDisable() {
        let alertVC = UIAlertController(title: nil, message: LocalString("open_camera"), preferredStyle: .alert)
        let toSet = UIAlertAction(title: LocalString("to_setting"), style: .default) { (_) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let ok = UIAlertAction(title: LocalString("cancel"), style: .cancel, handler: { [weak self] (alertAction) in
            _ = self?.navigationController?.popViewController(animated: true)
        })
        alertVC.addAction(toSet)
        alertVC.addAction(ok)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        debugPrint("-----\(type(of: self))")
    }
    
}
extension LueQRCodeConstroller: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            let obj = metadataObjects.last as? AVMetadataMachineReadableCodeObject
            resultHandle(obj?.stringValue)
        }
    }
}

class LueScanBgView: UIView {
    convenience init(frame: CGRect, inter interRect: CGRect) {
        self.init(frame: frame)
        self.interRect = interRect
    }

    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var interRect: CGRect!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        UIColor(white: 0, alpha: 0.4).setFill()
        UIRectFill(rect)
        
        let holeInter = rect.intersection(interRect)
        UIColor.clear.setFill()
        
        UIRectFill(holeInter)
    }
}
class LueScanAnimationView: UIView {
    convenience init(frame: CGRect, c lineColor: UIColor) {
        self.init(frame: frame)
        self.scanImage?.tintColor = lineColor
        self.lineColor = lineColor
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    
        let scanImage = UIImageView(image: #imageLiteral(resourceName: "scan_net"))
        scanImage.frame = CGRect(x: 0, y: 0, width: frame.width, height: 0)
        addSubview(scanImage)
        
        self.scanImage = scanImage
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var lineColor: UIColor!
    private var scanImage: UIImageView?
    
    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(updateScanImageHeight))
        return link
    }()
    
    func start() {
        displayLink.add(to: .main, forMode: .common)
    }
    func stop() {
        displayLink.invalidate()
    }
    
    @objc private func updateScanImageHeight() {
        guard var frame = scanImage?.frame else {
            return
        }
        frame.size.height += 2.4
        if frame.height > bounds.height {
            frame.size.height = 0
        }
        scanImage?.frame = frame
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCorner()
    }
    private func drawCorner() {
        let w = frame.width
        let h = frame.height
        let l: CGFloat = 20 // lineLength
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(lineColor.cgColor)
        context?.setLineWidth(3.6)
        
        // left up
        draw(context, [(0, 0), (l, 0), (0, l)])
        // right up
        draw(context, [(w, 0), (w, l), (w - l, 0)])
        // right down
        draw(context, [(w, h), (w - l, h), (w, h - l)])
        // left down
        draw(context, [(0, h), (0, h - l), (l, h)])
    }
    private func draw(_ context: CGContext?, _ points: [(x: CGFloat, y: CGFloat)]) {
        var ps = points
        guard let move = ps.popLast() else {
            return
        }
        let path = CGMutablePath()
        path.move(to: CGPoint(x: move.x, y: move.y))
        
        ps.forEach { (p) in
            path.addLine(to: CGPoint(x: p.x, y: p.y))
        }
        context?.addPath(path)
        context?.strokePath()
    }
}
