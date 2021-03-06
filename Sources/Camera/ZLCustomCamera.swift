//
//  ZLCustomCamera.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/11.
//

import UIKit
import AVFoundation
import CoreMotion

public class ZLCustomCamera: UIViewController, CAAnimationDelegate {

    struct Layout {
        
        static let bottomViewH: CGFloat = 150
        
        static let largeCircleRadius: CGFloat = 85
        
        static let smallCircleRadius: CGFloat = 62
        
        static let largeCircleRecordScale: CGFloat = 1.2
        
        static let smallCircleRecordScale: CGFloat = 0.7
        
    }
    
    public var takeDoneBlock: ( (UIImage?, URL?) -> Void )?
    
    var tipsLabel: UILabel!
    
    var hideTipsTimer: Timer?
    
    var bottomView: UIView!
    
    var largeCircleView: UIVisualEffectView!
    
    var smallCircleView: UIView!
    
    var animateLayer: CAShapeLayer!
    
    var retakeBtn: UIButton!
    
    var editBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var dismissBtn: UIButton!
    
    var toggleCameraBtn: UIButton!
    
    var focusCursorView: UIImageView!
    
    var takedImageView: UIImageView!
    
    var takedImage: UIImage?
    
    var videoUrl: URL?
    
    var motionManager: CMMotionManager?
    
    var orientation: AVCaptureVideoOrientation = .portrait
    
    let session = AVCaptureSession()
    
    var videoInput: AVCaptureDeviceInput?
    
    var imageOutput: AVCapturePhotoOutput!
    
    var movieFileOutput: AVCaptureMovieFileOutput!
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var recordVideoPlayerLayer: AVPlayerLayer?
    
    var cameraConfigureFinish = false
    
    var layoutOK = false
    
    var dragStart = false
    
    var viewDidAppearCount = 0
    
    // 仅支持竖屏
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        debugPrint("ZLCustomCamera deinit")
        self.cleanTimer()
        if self.session.isRunning {
            self.session.stopRunning()
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    @objc public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        self.setupCamera()
        self.observerDeviceMotion()
        self.addNotification()
        
        AVCaptureDevice.requestAccess(for: .video) { (videoGranted) in
            if videoGranted {
                if ZLPhotoConfiguration.default().allowRecordVideo {
                    AVCaptureDevice.requestAccess(for: .audio) { (audioGranted) in
                        if !audioGranted {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.showAlertAndDismissAfterDoneAction(message: String(format: localLanguageTextValue(.noMicrophoneAuthority), getAppName()))
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.showAlertAndDismissAfterDoneAction(message: String(format: localLanguageTextValue(.noCameraAuthority), getAppName()))
                })
            }
        }
        if ZLPhotoConfiguration.default().allowRecordVideo {
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable))
        } else if !ZLPhotoConfiguration.default().allowSelectImage, !ZLPhotoConfiguration.default().allowRecordVideo {
            #if DEBUG
            fatalError("参数配置错误")
            #else
            showAlertAndDismissAfterDoneAction(message: "相机参数配置错误")
            #endif
        } else if self.cameraConfigureFinish, self.viewDidAppearCount == 0 {
            self.showTipsLabel(animate: true)
            self.session.startRunning()
            self.setFocusCusor(point: self.view.center)
        }
        self.viewDidAppearCount += 1
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.motionManager?.stopDeviceMotionUpdates()
        self.motionManager = nil
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.session.stopRunning()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !self.layoutOK else { return }
        self.layoutOK = true
        
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
        }
        self.previewLayer?.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: self.view.bounds.height)
        self.recordVideoPlayerLayer?.frame = self.view.bounds
        self.takedImageView.frame = self.view.bounds
        
        self.bottomView.frame = CGRect(x: 0, y: self.view.bounds.height-insets.bottom-ZLCustomCamera.Layout.bottomViewH-50, width: self.view.bounds.width, height: ZLCustomCamera.Layout.bottomViewH)
        let largeCircleH = ZLCustomCamera.Layout.largeCircleRadius
        self.largeCircleView.frame = CGRect(x: (self.view.bounds.width-largeCircleH)/2, y: (ZLCustomCamera.Layout.bottomViewH-largeCircleH)/2, width: largeCircleH, height: largeCircleH)
        let smallCircleH = ZLCustomCamera.Layout.smallCircleRadius
        self.smallCircleView.frame = CGRect(x: (self.view.bounds.width-smallCircleH)/2, y: (ZLCustomCamera.Layout.bottomViewH-smallCircleH)/2, width: smallCircleH, height: smallCircleH)
        
        self.dismissBtn.frame = CGRect(x: 60, y: (ZLCustomCamera.Layout.bottomViewH-25)/2, width: 25, height: 25)
        
        self.tipsLabel.frame = CGRect(x: 0, y: self.bottomView.frame.minY-20, width: self.view.bounds.width, height: 20)
        
        self.retakeBtn.frame = CGRect(x: 30, y: insets.top+10, width: 28, height: 28)
        self.toggleCameraBtn.frame = CGRect(x: self.view.bounds.width-30-28, y: insets.top+10, width: 28, height: 28)
        
        let editBtnW = localLanguageTextValue(.edit).boundingRect(font: ZLThumbnailViewController.Layout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40)).width
        self.editBtn.frame = CGRect(x: 20, y: self.view.bounds.height - insets.bottom - ZLThumbnailViewController.Layout.bottomToolBtnH - 40, width: editBtnW, height: ZLThumbnailViewController.Layout.bottomToolBtnH)
        
        let doneBtnW = localLanguageTextValue(.done).boundingRect(font: ZLThumbnailViewController.Layout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40)).width + 20
        self.doneBtn.frame = CGRect(x: self.view.bounds.width - doneBtnW - 20, y: self.view.bounds.height - insets.bottom - ZLThumbnailViewController.Layout.bottomToolBtnH - 40, width: doneBtnW, height: ZLThumbnailViewController.Layout.bottomToolBtnH)
    }
    
    func setupUI() {
        self.view.backgroundColor = .black
        
        self.takedImageView = UIImageView()
        self.takedImageView.backgroundColor = .black
        self.takedImageView.isHidden = true
        self.takedImageView.contentMode = .scaleAspectFit
        self.view.addSubview(self.takedImageView)
        
        self.focusCursorView = UIImageView(image: getImage("zl_focus"))
        self.focusCursorView.contentMode = .scaleAspectFit
        self.focusCursorView.clipsToBounds = true
        self.focusCursorView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        self.focusCursorView.alpha = 0
        self.view.addSubview(self.focusCursorView)
        
        self.tipsLabel = UILabel()
        self.tipsLabel.font = getFont(14)
        self.tipsLabel.textColor = .white
        self.tipsLabel.textAlignment = .center
        self.tipsLabel.alpha = 0
        self.tipsLabel.text = localLanguageTextValue(.customCameraTips)
        self.view.addSubview(self.tipsLabel)
        
        self.bottomView = UIView()
        self.view.addSubview(self.bottomView)
        
        self.dismissBtn = UIButton(type: .custom)
        self.dismissBtn.setImage(getImage("zl_arrow_down"), for: .normal)
        self.dismissBtn.addTarget(self, action: #selector(dismissBtnClick), for: .touchUpInside)
        self.dismissBtn.adjustsImageWhenHighlighted = false
        self.dismissBtn.zl_enlargeValidTouchArea(inset: 30)
        self.bottomView.addSubview(self.dismissBtn)
        if #available(iOS 13.0, *) {
            self.largeCircleView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        } else {
            self.largeCircleView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        }
        self.largeCircleView.layer.masksToBounds = true
        self.largeCircleView.layer.cornerRadius = ZLCustomCamera.Layout.largeCircleRadius / 2
        self.bottomView.addSubview(self.largeCircleView)
        
        self.smallCircleView = UIView()
        self.smallCircleView.layer.masksToBounds = true
        self.smallCircleView.layer.cornerRadius = ZLCustomCamera.Layout.smallCircleRadius / 2
        self.smallCircleView.isUserInteractionEnabled = false
        self.smallCircleView.backgroundColor = .white
        self.bottomView.addSubview(self.smallCircleView)
        
        self.animateLayer = CAShapeLayer()
        let animateLayerRadius = ZLCustomCamera.Layout.largeCircleRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: animateLayerRadius, height: animateLayerRadius), cornerRadius: animateLayerRadius/2)
        self.animateLayer.path = path.cgPath
        self.animateLayer.strokeColor = UIColor.cameraRecodeProgressColor.cgColor
        self.animateLayer.fillColor = UIColor.clear.cgColor
        self.animateLayer.lineWidth = 8
        
        if ZLPhotoConfiguration.default().allowSelectImage {
            let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(takePicture))
            self.largeCircleView.addGestureRecognizer(takePictureTap)
        }
        if ZLPhotoConfiguration.default().allowRecordVideo {
            let recordLongPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
            recordLongPress.minimumPressDuration = 0.3
            recordLongPress.delegate = self
            self.largeCircleView.addGestureRecognizer(recordLongPress)
        }
        
        self.retakeBtn = UIButton(type: .custom)
        self.retakeBtn.setImage(getImage("zl_retake"), for: .normal)
        self.retakeBtn.addTarget(self, action: #selector(retakeBtnClick), for: .touchUpInside)
        self.retakeBtn.isHidden = true
        self.retakeBtn.adjustsImageWhenHighlighted = false
        self.retakeBtn.zl_enlargeValidTouchArea(inset: 30)
        self.view.addSubview(self.retakeBtn)
        
        self.toggleCameraBtn = UIButton(type: .custom)
        self.toggleCameraBtn.setImage(getImage("zl_toggle_camera"), for: .normal)
        self.toggleCameraBtn.addTarget(self, action: #selector(toggleCameraBtnClick), for: .touchUpInside)
        self.toggleCameraBtn.adjustsImageWhenHighlighted = false
        self.toggleCameraBtn.zl_enlargeValidTouchArea(inset: 30)
        self.view.addSubview(self.toggleCameraBtn)
        
        self.editBtn = UIButton(type: .custom)
        self.editBtn.titleLabel?.font = ZLThumbnailViewController.Layout.bottomToolTitleFont
        self.editBtn.setTitle(localLanguageTextValue(.edit), for: .normal)
        self.editBtn.setTitleColor(.bottomToolViewBtnNormalTitleColor, for: .normal)
        self.editBtn.addTarget(self, action: #selector(editBtnClick), for: .touchUpInside)
        self.editBtn.isHidden = true
        // 字体周围添加一点阴影
        self.editBtn.titleLabel?.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.editBtn.titleLabel?.layer.shadowOffset = .zero
        self.editBtn.titleLabel?.layer.shadowOpacity = 1;
        self.view.addSubview(self.editBtn)
        
        self.doneBtn = UIButton(type: .custom)
        self.doneBtn.titleLabel?.font = ZLThumbnailViewController.Layout.bottomToolTitleFont
        self.doneBtn.setTitle(localLanguageTextValue(.done), for: .normal)
        self.doneBtn.setTitleColor(.bottomToolViewBtnNormalTitleColor, for: .normal)
        self.doneBtn.backgroundColor = .bottomToolViewBtnNormalBgColor
        self.doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.doneBtn.isHidden = true
        self.doneBtn.layer.masksToBounds = true
        self.doneBtn.layer.cornerRadius = 5
        self.view.addSubview(self.doneBtn)
        
        let focusCursorTap = UITapGestureRecognizer(target: self, action: #selector(adjustFocusPoint))
        focusCursorTap.delegate = self
        self.view.addGestureRecognizer(focusCursorTap)
        
        if ZLPhotoConfiguration.default().allowRecordVideo {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(adjustCameraFocus(_:)))
            pan.maximumNumberOfTouches = 1
            self.view.addGestureRecognizer(pan)
            
            self.recordVideoPlayerLayer = AVPlayerLayer()
            self.recordVideoPlayerLayer?.backgroundColor = UIColor.black.cgColor
            self.recordVideoPlayerLayer?.videoGravity = .resizeAspect
            self.recordVideoPlayerLayer?.isHidden = true
            self.view.layer.insertSublayer(self.recordVideoPlayerLayer!, at: 0)
            
            NotificationCenter.default.addObserver(self, selector: #selector(recordVideoPlayFinished), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    func observerDeviceMotion() {
        self.motionManager = CMMotionManager()
        self.motionManager?.deviceMotionUpdateInterval = 0.5
        
        if self.motionManager?.isDeviceMotionAvailable == true {
            self.motionManager?.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (motion, error) in
                if let _ = motion {
                    self.handleDeviceMotion(motion!)
                }
            })
        } else {
            self.motionManager = nil
        }
    }
    
    func handleDeviceMotion(_ motion: CMDeviceMotion) {
        let x = motion.gravity.x
        let y = motion.gravity.y
        
        if abs(y) >= abs(x) {
            if y >= 0 {
                self.orientation = .portraitUpsideDown
            } else {
                self.orientation = .portrait
            }
        } else {
            if x >= 0 {
                self.orientation = .landscapeLeft
            } else {
                self.orientation = .landscapeRight
            }
        }
    }
    
    func setupCamera() {
        guard let backCamera = self.getCamera(position: .back) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: backCamera) else { return }
        // 相机画面输入流
        self.videoInput = input
        // 照片输出流
        self.imageOutput = AVCapturePhotoOutput()
        
        // 音频输入流
        var audioInput: AVCaptureDeviceInput?
        if ZLPhotoConfiguration.default().allowRecordVideo, let microphone = self.getMicrophone() {
            audioInput = try? AVCaptureDeviceInput(device: microphone)
        }
        
        let preset = ZLPhotoConfiguration.default().sessionPreset.avSessionPreset
        if self.session.canSetSessionPreset(preset) {
            self.session.sessionPreset = preset
        } else {
            self.session.sessionPreset = .hd1280x720
        }
        
        self.movieFileOutput = AVCaptureMovieFileOutput()
        // 解决视频录制超过10s没有声音的bug
        self.movieFileOutput.movieFragmentInterval = .invalid
        
        // 将视频及音频输入流添加到session
        if let vi = self.videoInput, self.session.canAddInput(vi) {
            self.session.addInput(vi)
        }
        if let ai = audioInput, self.session.canAddInput(ai) {
            self.session.addInput(ai)
        }
        // 将输出流添加到session
        if self.session.canAddOutput(self.imageOutput) {
            self.session.addOutput(self.imageOutput)
        }
        if self.session.canAddOutput(self.movieFileOutput) {
            self.session.addOutput(self.movieFileOutput)
        }
        // 预览layer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer?.videoGravity = .resizeAspect
        self.view.layer.masksToBounds = true
        self.view.layer.insertSublayer(self.previewLayer!, at: 0)
        
        self.cameraConfigureFinish = true
    }
    
    func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func getMicrophone() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices.first
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func showAlertAndDismissAfterDoneAction(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: localLanguageTextValue(.done), style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        self.showDetailViewController(alert, sender: nil)
    }
    
    func showTipsLabel(animate: Bool) {
        self.tipsLabel.layer.removeAllAnimations()
        if animate {
            UIView.animate(withDuration: 0.25) {
                self.tipsLabel.alpha = 1
            }
        } else {
            self.tipsLabel.alpha = 1
        }
        self.startHideTipsLabelTimer()
    }
    
    func hideTipsLabel(animate: Bool) {
        self.cleanTimer()
        self.tipsLabel.layer.removeAllAnimations()
        if animate {
            UIView.animate(withDuration: 0.25) {
                self.tipsLabel.alpha = 0
            }
        } else {
            self.tipsLabel.alpha = 0
        }
    }
    
    func startHideTipsLabelTimer() {
        self.cleanTimer()
        self.hideTipsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
            self.hideTipsLabel(animate: true)
        })
    }
    
    func cleanTimer() {
        self.hideTipsTimer?.invalidate()
        self.hideTipsTimer = nil
    }
    
    @objc func appWillResignActive() {
        if self.session.isRunning {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func dismissBtnClick() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func retakeBtnClick() {
        self.session.startRunning()
        self.resetSubViewStatus()
        self.takedImage = nil
        self.stopRecordAnimation()
        if let url = self.videoUrl {
            self.recordVideoPlayerLayer?.player?.pause()
            self.recordVideoPlayerLayer?.player = nil
            self.recordVideoPlayerLayer?.isHidden = true
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    @objc func toggleCameraBtnClick() {
        let cameraCount = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.count
        guard cameraCount > 1 else {
            return
        }
        do {
            guard let currInput = self.videoInput else {
                return
            }
            var newVideoInput: AVCaptureDeviceInput?
            if currInput.device.position == .back, let front = self.getCamera(position: .front) {
                newVideoInput = try AVCaptureDeviceInput(device: front)
            } else if currInput.device.position == .front, let back = self.getCamera(position: .back) {
                newVideoInput = try AVCaptureDeviceInput(device: back)
            } else {
                return
            }
            if let ni = newVideoInput {
                self.session.beginConfiguration()
                self.session.removeInput(currInput)
                if self.session.canAddInput(ni) {
                    self.session.addInput(ni)
                    self.videoInput = ni
                } else {
                    self.session.addInput(currInput)
                }
                self.session.commitConfiguration()
            }
        } catch {
            debugPrint("切换摄像头失败 \(error.localizedDescription)")
        }
    }
    
    @objc func editBtnClick() {
        guard let image = self.takedImage else {
            return
        }
        let vc = ZLEditImageViewController(image: image)
        vc.modalPresentationStyle = .fullScreen
        vc.editFinishBlock = { [weak self] (ei) in
            guard let `self` = self else { return }
            self.dismiss(animated: true) {
                self.takeDoneBlock?(ei, nil)
            }
        }
        self.present(vc, animated: false, completion: nil)
    }
    
    @objc func doneBtnClick() {
        self.recordVideoPlayerLayer?.player?.pause()
        self.recordVideoPlayerLayer?.player = nil
        self.dismiss(animated: true) {
            self.takeDoneBlock?(self.takedImage, self.videoUrl)
        }
    }
    
    // 点击拍照
    @objc func takePicture() {
        let connection = self.imageOutput.connection(with: .video)
        connection?.videoOrientation = self.orientation
        let setting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        if self.videoInput?.device.hasFlash == true {
            setting.flashMode = ZLPhotoConfiguration.default().cameraFlashMode.avFlashMode
        }
        self.imageOutput.capturePhoto(with: setting, delegate: self)
    }
    
    // 长按录像
    @objc func longPressAction(_ longGes: UILongPressGestureRecognizer) {
        if longGes.state == .began {
            self.startRecord()
        } else if longGes.state == .cancelled || longGes.state == .ended {
            debugPrint("---- long press end")
            self.finishRecord()
        }
    }
    
    // 调整焦点
    @objc func adjustFocusPoint(_ tap: UITapGestureRecognizer) {
        guard self.session.isRunning else {
            return
        }
        let point = tap.location(in: self.view)
        if point.y > self.bottomView.frame.minY - 30 {
            return
        }
        self.setFocusCusor(point: point)
    }
    
    func setFocusCusor(point: CGPoint) {
        self.focusCursorView.center = point
        self.focusCursorView.layer.removeAllAnimations()
        self.focusCursorView.alpha = 1
        self.focusCursorView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
        UIView.animate(withDuration: 0.5, animations: {
            self.focusCursorView.layer.transform = CATransform3DIdentity
        }) { (_) in
            self.focusCursorView.alpha = 0
        }
        // ui坐标转换为摄像头坐标
        let cameraPoint = self.previewLayer?.captureDevicePointConverted(fromLayerPoint: point) ?? self.view.center
        self.focusCamera(mode: .autoFocus, exposureMode: .autoExpose, point: cameraPoint)
    }
    
    // 调整焦距
    @objc func adjustCameraFocus(_ pan: UIPanGestureRecognizer) {
        let convertRect = self.bottomView.convert(self.largeCircleView.frame, to: self.view)
        let point = pan.location(in: self.view)
        
        if pan.state == .began {
            if !convertRect.contains(point) {
                return
            }
            self.dragStart = true
            self.startRecord()
        } else if pan.state == .changed {
            guard self.dragStart else {
                return
            }
            let maxZoomFactor = self.videoInput?.device.formats.first?.videoMaxZoomFactor ?? 10
            var zoomFactor = (convertRect.midY - point.y) / convertRect.midY * 10
            zoomFactor = max(1, min(zoomFactor, maxZoomFactor))
            self.setVideoZoomFactor(zoomFactor)
        } else if pan.state == .cancelled || pan.state == .ended {
            debugPrint("---- pan end")
            guard self.dragStart else {
                return
            }
            self.dragStart = false
            self.finishRecord()
        }
    }
    
    func setVideoZoomFactor(_ zoomFactor: CGFloat) {
        guard let device = self.videoInput?.device else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
            debugPrint("调整焦距失败 \(error.localizedDescription)")
        }
    }
    
    
    func focusCamera(mode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, point: CGPoint) {
        do {
            guard let device = self.videoInput?.device else {
                return
            }
            
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(mode) {
                device.focusMode = mode
            }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
            }
            
            device.unlockForConfiguration()
        } catch {
            debugPrint("相机聚焦设置失败 \(error.localizedDescription)")
        }
    }
    
    func startRecord() {
        guard !self.movieFileOutput.isRecording else {
            return
        }
        self.dismissBtn.isHidden = true
        self.toggleCameraBtn.isHidden = true
        let connection = self.movieFileOutput.connection(with: .video)
        connection?.videoOrientation = self.orientation
        connection?.videoScaleAndCropFactor = 1
        let url = URL(fileURLWithPath: ZLPhotoManager.getVideoExportFilePath())
        self.movieFileOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    func finishRecord() {
        guard self.movieFileOutput.isRecording else {
            return
        }
        self.movieFileOutput.stopRecording()
        self.session.stopRunning()
        self.stopRecordAnimation()
        self.resetSubViewStatus()
    }
    
    func startRecordAnimation() {
        UIView.animate(withDuration: 0.1, animations: {
            self.largeCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, ZLCustomCamera.Layout.largeCircleRecordScale, ZLCustomCamera.Layout.largeCircleRecordScale, 1)
            self.smallCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, ZLCustomCamera.Layout.smallCircleRecordScale, ZLCustomCamera.Layout.smallCircleRecordScale, 1)
        }) { (_) in
            self.largeCircleView.layer.addSublayer(self.animateLayer)
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = Double(ZLPhotoConfiguration.default().maxRecordDuration)
            animation.delegate = self
            self.animateLayer.add(animation, forKey: nil)
        }
    }
    
    func stopRecordAnimation() {
        self.animateLayer.removeFromSuperlayer()
        self.animateLayer.removeAllAnimations()
        self.largeCircleView.transform = .identity
        self.smallCircleView.transform = .identity
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.finishRecord()
    }
    
    func resetSubViewStatus() {
        debugPrint("---- isrunning \(self.session.isRunning)")
        if self.session.isRunning {
            self.showTipsLabel(animate: true)
            self.bottomView.isHidden = false
            self.dismissBtn.isHidden = false
            self.toggleCameraBtn.isHidden = false
            self.retakeBtn.isHidden = true
            self.editBtn.isHidden = true
            self.doneBtn.isHidden = true
            self.takedImageView.isHidden = true
            self.takedImage = nil
        } else {
            self.hideTipsLabel(animate: false)
            self.bottomView.isHidden = true
            self.dismissBtn.isHidden = true
            self.toggleCameraBtn.isHidden = true
            self.retakeBtn.isHidden = false
            self.editBtn.isHidden = self.takedImage == nil
            self.doneBtn.isHidden = false
        }
    }
    
    func playRecordVideo(fileUrl: URL) {
        self.recordVideoPlayerLayer?.isHidden = false
        let player = AVPlayer(url: fileUrl)
        player.automaticallyWaitsToMinimizeStalling = false
        self.recordVideoPlayerLayer?.player = player
        player.play()
    }
    
    @objc func recordVideoPlayFinished() {
        self.recordVideoPlayerLayer?.player?.seek(to: .zero)
        self.recordVideoPlayerLayer?.player?.play()
    }

}


extension ZLCustomCamera: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if photoSampleBuffer == nil || error != nil {
            debugPrint("拍照失败 \(error?.localizedDescription ?? "")")
            return
        }
        
        if let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
            self.session.stopRunning()
            self.takedImage = UIImage(data: data)?.fixOrientation()
            self.takedImageView.image = self.takedImage
            self.takedImageView.isHidden = false
            self.resetSubViewStatus()
        } else {
            debugPrint("拍照失败，data为空")
        }
    }
    
}


extension ZLCustomCamera: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.startRecordAnimation()
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if output.recordedDuration.seconds < 0.3 {
            //视频长度小于0.3s 允许拍照则拍照，不允许拍照，则保存小于0.3s的视频
            if ZLPhotoConfiguration.default().allowSelectImage {
                self.takePicture()
                return
            }
        }
        
        self.videoUrl = outputFileURL
        self.playRecordVideo(fileUrl: outputFileURL)
    }
    
}


extension ZLCustomCamera: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer is UILongPressGestureRecognizer, otherGestureRecognizer is UIPanGestureRecognizer {
//            return true
//        }
        return true
    }
    
}


extension ZLCustomCamera {
    
    @objc public enum CaptureSessionPreset: Int {
        
        var avSessionPreset: AVCaptureSession.Preset {
            switch self {
            case .cif352x288:
                return .cif352x288
            case .vga640x480:
                return .vga640x480
            case .hd1280x720:
                return .hd1280x720
            case .hd1920x1080:
                return .hd1920x1080
            case .hd4K3840x2160:
                return .hd4K3840x2160
            }
        }
        
        case cif352x288
        case vga640x480
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
    }
    
    @objc public enum CameraFlashMode: Int  {
        
        // 转自定义相机
        var avFlashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .auto:
                return .auto
            case .on:
                return .on
            case .off:
                return .off
            }
        }
        
        // 转系统相机
        var imagePickerFlashMode: UIImagePickerController.CameraFlashMode {
            switch self {
            case .auto:
                return .auto
            case .on:
                return .on
            case .off:
                return .off
            }
        }
        
        case auto
        case on
        case off
    }
    
    @objc public enum VideoExportType: Int {
        
        var format: String {
            switch self {
            case .mov:
                return "mov"
            case .mp4:
                return "mp4"
            }
        }
        
        var avFileType: AVFileType {
            switch self {
            case .mov:
                return .mov
            case .mp4:
                return .mp4
            }
        }
        
        case mov
        case mp4
    }
    
}
