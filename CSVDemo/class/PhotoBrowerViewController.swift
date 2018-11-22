//
//  PhotoBrowerViewController.swift
//  
//
//  Created by luiz on 16/12/16.
//  Copyright © 2016年 lue. All rights reserved.
//

import UIKit
import PhotosUI

private let reuseIdentifier = "pbCell"

class PhotoBrowerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    let kScreenWidth = UIScreen.main.bounds.width
    let kScreenHeight = UIScreen.main.bounds.height
    
    var currentIndex = 0
    
    var dataArr: Array<Any> = [] // 只能是image或者图片地址
    // 兼容 iOS 8.0
    init() {
        super.init(nibName: "PhotoBrowerViewController", bundle: Bundle.main)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flowLayout.itemSize = CGSize(width: kScreenWidth, height: kScreenHeight)
        self.collectionView.register(PhotoBrowerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(PhotoBrowerViewController.dismissSelf))
        self.view.addGestureRecognizer(tap)
    }
    override func viewDidLayoutSubviews() {
        self.collectionView.scrollToItem(at: IndexPath.init(row: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
    }
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - colllection view 数据源
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArr.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoBrowerCell
        cell.model = self.dataArr[indexPath.row]
        return cell
    }
}
// cell
class PhotoBrowerCell: UICollectionViewCell, UIScrollViewDelegate {
    
    var imgView: UIImageView!
    var scrollView: UIScrollView!
    var reportBtn: UIButton!
    var model: Any? {
        willSet(m) {
            if let str = m as? String {
//                self.imgView.kf.setImage(with: URL(string: str))
            } else if let img = m as? UIImage {
                self.imgView.image = img
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scrollView = UIScrollView(frame: self.bounds)
        self.scrollView.contentSize = self.bounds.size
        self.contentView.addSubview(self.scrollView)
        self.imgView = UIImageView(frame: self.bounds)
        self.imgView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(self.imgView)
        
        self.scrollView.delegate = self
        self.scrollView.maximumZoomScale = 3
        self.scrollView.minimumZoomScale = 0.5
        self.scrollView.isMultipleTouchEnabled = true
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(PhotoBrowerCell.savePictrue))
        
        self.addGestureRecognizer(longTap)
    }
    // 保存图片
    @objc func savePictrue() {
        if let img = imgView.image {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let action = UIAlertAction(title: LocalString("save"), style: .default) { (a) in
                switch PHPhotoLibrary.authorizationStatus() {
                case .authorized: UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization({ (s) in
                        if s == .authorized {
                            UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
                        }
                    })
                default: self.deviceDisable()
                }
            }
            let cancel = UIAlertAction(title: LocalString("cancel"), style: .cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancel)
            self.responderViewController()?.present(alert, animated: true, completion: nil)
        }
    }
    func deviceDisable() {
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
        let ok = UIAlertAction(title: LocalString("cancel"), style: .cancel, handler: nil)
        alertVC.addAction(toSet)
        alertVC.addAction(ok)
        self.responderViewController()?.present(alertVC, animated: true, completion: nil)
    }
    @objc func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error != nil {
            showMessage(LocalString("failure"))
        } else {
            showMessage(LocalString("save.success"))
        }
    }
    // MARK: - scroll view 代理
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = scrollView.bounds.width > scrollView.contentSize.width ? (scrollView.bounds.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = scrollView.bounds.height > scrollView.contentSize.height ? (scrollView.bounds.height - scrollView.contentSize.height) * 0.5 : 0
        self.imgView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.setZoomScale(scale, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


// TODO: -- 未完成
func LocalString(_ str: String) -> String {
    return str
}

