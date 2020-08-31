//
//  ZLClipImageViewController.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/27.
//

import UIKit

extension ZLClipImageViewController {
    
    enum ClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
}


class ZLClipImageViewController: UIViewController {

    static let bottomToolViewH: CGFloat = 100
    
    /// 用作进入裁剪界面首次动画
    var animateOriginFrame: CGRect = .zero
    
    var viewDidAppearCount = 0
    
    let originalImage: UIImage
    
    var editImage: UIImage
    
    var scrollView: UIScrollView!
    
    var containerView: UIView!
    
    var imageView: UIImageView!
    
    var shadowView: ZLClipShadowView!
    
    var overlayView: ZLClipOverlayView!
    
    var gridPanGes: UIPanGestureRecognizer!
    
    var bottomToolView: UIView!
    
    var bottomShadowLayer: CAGradientLayer!
    
    var bottomToolLineView: UIView!
    
    var cancelBtn: UIButton!
    
    var revertBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var rotateBtn: UIButton!
    
    var shouldLayout = true
    
    var panEdge: ZLClipImageViewController.ClipPanEdge = .none
    
    var beginPanPoint: CGPoint = .zero
    
    var clipBoxFrame: CGRect = .zero
    
    var clipOriginFrame: CGRect = .zero
    
    var isRotating = false
    
    var angle = 0
    
    var maxClipFrame: CGRect = {
        var insets = deviceSafeAreaInsets()
        insets.top += (insets.top == 0) ? 40 : 20
        var rect = CGRect.zero
        rect.origin.x = 15
        rect.origin.y = insets.top
        rect.size.width = UIScreen.main.bounds.width - 15 * 2
        rect.size.height = UIScreen.main.bounds.height - insets.top - insets.bottom - ZLClipImageViewController.bottomToolViewH - 40
        return rect
    }()
    
    var minClipSize = CGSize(width: 45, height: 45)
    
    var resetTimer: Timer?
    
    var clipDoneBlock: ( (UIImage, CGRect) -> Void )?
    
    var cancelClipBlock: ( (UIImage?, CGRect) -> Void )?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    deinit {
        debugPrint("ZLClipImageViewController deinit")
        self.cleanTimer()
    }
    
    init(image: UIImage) {
        self.originalImage = image
        self.editImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.viewDidAppearCount == 0 {
            let animateImageView = UIImageView(image: self.originalImage)
            animateImageView.contentMode = .scaleAspectFit
            animateImageView.frame = self.animateOriginFrame
            self.view.addSubview(animateImageView)
            
            self.scrollView.alpha = 0
            self.overlayView.alpha = 0
            self.bottomToolView.alpha = 0
            self.rotateBtn.alpha = 0
            let toRect = self.view.convert(self.containerView.frame, from: self.scrollView)
            UIView.animate(withDuration: 0.25, animations: {
                animateImageView.frame = toRect
                self.bottomToolView.alpha = 1
                self.rotateBtn.alpha = 1
            }) { (_) in
                animateImageView.removeFromSuperview()
                self.scrollView.alpha = 1
                self.overlayView.alpha = 1
            }
        }
        self.viewDidAppearCount += 1
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.shouldLayout else {
            return
        }
        self.shouldLayout = false
        
        self.scrollView.frame = self.view.bounds
        self.shadowView.frame = self.view.bounds
        
        self.layoutInitialImage()
        
        self.bottomToolView.frame = CGRect(x: 0, y: self.view.bounds.height-ZLClipImageViewController.bottomToolViewH, width: self.view.bounds.width, height: ZLClipImageViewController.bottomToolViewH)
        self.bottomShadowLayer.frame = self.bottomToolView.bounds
        
        self.bottomToolLineView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 1/UIScreen.main.scale)
        let toolBtnH: CGFloat = 25
        let toolBtnY = (ZLClipImageViewController.bottomToolViewH - toolBtnH) / 2 - 10
        self.cancelBtn.frame = CGRect(x: 30, y: toolBtnY, width: toolBtnH, height: toolBtnH)
        let revertBtnW = localLanguageTextValue(.revert).boundingRect(font: ZLThumbnailViewController.Layout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: toolBtnH)).width + 20
        self.revertBtn.frame = CGRect(x: (self.view.bounds.width-revertBtnW)/2, y: toolBtnY, width: revertBtnW, height: toolBtnH)
        self.doneBtn.frame = CGRect(x: self.view.bounds.width-30-toolBtnH, y: toolBtnY, width: toolBtnH, height: toolBtnH)
        
        self.rotateBtn.frame = CGRect(x: 30, y: self.bottomToolView.frame.minY-50, width: 25, height: 25)
    }
    
    func setupUI() {
        self.view.backgroundColor = .black
        
        self.scrollView = UIScrollView()
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.alwaysBounceHorizontal = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
        
        self.containerView = UIView()
        self.scrollView.addSubview(self.containerView)
        
        self.imageView = UIImageView(image: self.originalImage)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.containerView.addSubview(self.imageView)
        
        self.shadowView = ZLClipShadowView()
        self.shadowView.isUserInteractionEnabled = false
        self.shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.view.addSubview(self.shadowView)
        
        self.overlayView = ZLClipOverlayView()
        self.overlayView.isUserInteractionEnabled = false
        self.view.addSubview(self.overlayView)
        
        self.bottomToolView = UIView()
        self.view.addSubview(self.bottomToolView)
        
        let color1 = UIColor.black.withAlphaComponent(0.15).cgColor
        let color2 = UIColor.black.withAlphaComponent(0.35).cgColor
        
        self.bottomShadowLayer = CAGradientLayer()
        self.bottomShadowLayer.colors = [color1, color2]
        self.bottomShadowLayer.locations = [0, 1]
        self.bottomToolView.layer.addSublayer(self.bottomShadowLayer)
        
        self.bottomToolLineView = UIView()
        self.bottomToolLineView.backgroundColor = zlRGB(240, 240, 240)
        self.bottomToolView.addSubview(self.bottomToolLineView)
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setImage(getImage("zl_close"), for: .normal)
        self.cancelBtn.adjustsImageWhenHighlighted = false
        self.cancelBtn.zl_enlargeValidTouchArea(inset: 20)
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        self.bottomToolView.addSubview(self.cancelBtn)
        
        self.revertBtn = UIButton(type: .custom)
        self.revertBtn.setTitleColor(.white, for: .normal)
        self.revertBtn.setTitle(localLanguageTextValue(.revert), for: .normal)
        self.revertBtn.zl_enlargeValidTouchArea(inset: 20)
        self.revertBtn.titleLabel?.font = ZLThumbnailViewController.Layout.bottomToolTitleFont
        self.revertBtn.addTarget(self, action: #selector(revertBtnClick), for: .touchUpInside)
        self.bottomToolView.addSubview(self.revertBtn)
        
        self.doneBtn = UIButton(type: .custom)
        self.doneBtn.setImage(getImage("zl_right"), for: .normal)
        self.doneBtn.adjustsImageWhenHighlighted = false
        self.doneBtn.zl_enlargeValidTouchArea(inset: 20)
        self.doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.bottomToolView.addSubview(self.doneBtn)
        
        self.rotateBtn = UIButton(type: .custom)
        self.rotateBtn.setImage(getImage("zl_rotateimage"), for: .normal)
        self.rotateBtn.adjustsImageWhenHighlighted = false
        self.rotateBtn.zl_enlargeValidTouchArea(inset: 20)
        self.rotateBtn.addTarget(self, action: #selector(rotateBtnClick), for: .touchUpInside)
        self.view.addSubview(self.rotateBtn)
        
        self.gridPanGes = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        self.gridPanGes.delegate = self
        self.view.addGestureRecognizer(self.gridPanGes)
        self.scrollView.panGestureRecognizer.require(toFail: self.gridPanGes)
    }
    
    func layoutInitialImage() {
        let imageSize = self.editImage.size
        self.scrollView.contentSize = imageSize
        let maxClipRect = self.maxClipFrame
        
        self.containerView.frame = CGRect(origin: .zero, size: self.editImage.size)
        self.imageView.frame = self.containerView.bounds
        
        let scale = min(maxClipRect.width/imageSize.width, maxClipRect.height/imageSize.height)
        
        let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        self.scrollView.minimumZoomScale = scale
        self.scrollView.maximumZoomScale = 10
        
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width-frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height-frame.height) / 2)
        self.changeClipBoxFrame(newFrame: frame)

        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        self.scrollView.contentSize = scaledSize
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((self.scrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((self.scrollView.frame.height - scaledSize.height) / 2)
            self.scrollView.contentOffset = offset
        }
    }
    
    func changeClipBoxFrame(newFrame: CGRect) {
        guard self.clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        let originX = ceil(self.maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = floor(max(frame.minX, originX))
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(self.maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = floor(max(frame.minY, originY))
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = self.maxClipFrame.width + self.maxClipFrame.minX - frame.minX
        frame.size.width = floor(max(self.minClipSize.width, min(frame.width, maxW)))
        
        let maxH = self.maxClipFrame.height + self.maxClipFrame.minY - frame.minY
        frame.size.height = floor(max(self.minClipSize.height, min(frame.height, maxH)))
        
        self.clipBoxFrame = frame
        self.shadowView.clearRect = frame
        self.overlayView.frame = frame.insetBy(dx: -ZLClipOverlayView.cornerLineWidth, dy: -ZLClipOverlayView.cornerLineWidth)
        
        self.scrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: self.scrollView.frame.maxY-frame.maxY, right: self.scrollView.frame.maxX-frame.maxX)
        
        let scale = max(frame.height/self.editImage.size.height, frame.width/self.editImage.size.width)
        self.scrollView.minimumZoomScale = scale
        
        var size = self.scrollView.contentSize
        size.width = floor(size.width)
        size.height = floor(size.height)
        self.scrollView.contentSize = size
        
        self.scrollView.zoomScale = self.scrollView.zoomScale
    }
    
    @objc func cancelBtnClick() {
        let image = self.angle == 0 ? self.originalImage : nil
        let frame = self.view.convert(self.containerView.frame, from: self.scrollView)
        self.dismiss(animated: false) {
            self.cancelClipBlock?(image, frame)
        }
    }
    
    @objc func revertBtnClick() {
        self.editImage = self.originalImage
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 1
        self.scrollView.zoomScale = 1
        self.imageView.image = self.editImage
        self.layoutInitialImage()
    }
    
    @objc func doneBtnClick() {
        let image = self.clipImage()
        self.dismiss(animated: false) {
            self.clipDoneBlock?(image, self.clipBoxFrame)
        }
    }
    
    @objc func rotateBtnClick() {
        guard !self.isRotating else {
            return
        }
        self.angle -= 90
        if self.angle == -360 {
            self.angle = 0
        }
        
        self.isRotating = true
        
        let animateImageView = UIImageView(image: self.editImage)
        animateImageView.contentMode = .scaleAspectFit
        animateImageView.clipsToBounds = true
        let originFrame = self.view.convert(self.containerView.frame, from: self.scrollView)
        animateImageView.frame = originFrame
        self.view.addSubview(animateImageView)
        
        self.editImage = self.editImage.rotate(orientation: .left)
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 1
        self.scrollView.zoomScale = 1
        self.imageView.image = self.editImage
        self.layoutInitialImage()
        
        let toFrame = self.view.convert(self.containerView.frame, from: self.scrollView)
        let transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        
        self.overlayView.alpha = 0
        self.containerView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            animateImageView.transform = transform
            animateImageView.frame = toFrame
        }) { (_) in
            animateImageView.removeFromSuperview()
            self.overlayView.alpha = 1
            self.containerView.alpha = 1
            self.isRotating = false
        }
    }
    
    @objc func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self.view)
        if pan.state == .began {
            self.startEditing()
            self.beginPanPoint = point
            self.clipOriginFrame = self.clipBoxFrame
            self.panEdge = self.calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard self.panEdge != .none else {
                return
            }
            self.updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            self.panEdge = .none
            self.startTimer()
        }
    }
    
    func calculatePanEdge(at point: CGPoint) -> ZLClipImageViewController.ClipPanEdge {
        let frame = self.clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let cornerSize = CGSize(width: 60, height: 60)
        let topLeftRect = CGRect(origin: frame.origin, size: cornerSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = CGRect(origin: CGPoint(x: frame.maxX-cornerSize.width, y: frame.minY), size: cornerSize)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY-cornerSize.height), size: cornerSize)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = CGRect(origin: CGPoint(x: frame.maxX-cornerSize.width, y: frame.maxY-cornerSize.height), size: cornerSize)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height))
        if topRect.contains(point) {
            return .top
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY-cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: frame.width-cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height))
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    func updateClipBoxFrame(point: CGPoint) {
        var frame = self.clipBoxFrame
        let originFrame = self.clipOriginFrame
        
        var newPoint = point
        newPoint.x = max(self.maxClipFrame.minX, newPoint.x)
        newPoint.y = max(self.maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - self.beginPanPoint.x)
        let diffY = ceil(newPoint.y - self.beginPanPoint.y)
        
        switch self.panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            
        case .right:
            frame.size.width = originFrame.width + diffX
            
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            
        case .bottom:
            frame.size.height = originFrame.height + diffY
            
        case .topLeft:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            
        case .topRight:
            frame.size.width = originFrame.width + diffX
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            
        case .bottomLeft:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            frame.size.height = originFrame.height + diffY
            
        case .bottomRight:
            frame.size.width = originFrame.width + diffX
            frame.size.height = originFrame.height + diffY
        
        default:
            break
        }
        
        let minSize = self.minClipSize
        let maxSize = self.maxClipFrame.size
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(self.maxClipFrame.maxX-minSize.width, max(frame.origin.x, self.maxClipFrame.minX))
        frame.origin.y = min(self.maxClipFrame.maxY-minSize.height, max(frame.origin.y, self.maxClipFrame.minY))
        
        if (self.panEdge == .topLeft || self.panEdge == .bottomLeft || self.panEdge == .left) && frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if (self.panEdge == .topLeft || self.panEdge == .topRight || self.panEdge == .top) && frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        self.changeClipBoxFrame(newFrame: frame)
    }
    
    func startEditing() {
        self.cleanTimer()
        self.shadowView.alpha = 0
        if self.rotateBtn.alpha != 0 {
            self.rotateBtn.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2) {
                self.rotateBtn.alpha = 0
            }
        }
    }
    
    func endEditing() {
        self.moveClipContentToCenter()
    }
    
    func startTimer() {
        self.cleanTimer()
        self.resetTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false, block: { (timer) in
            self.cleanTimer()
            self.endEditing()
        })
    }
    
    func cleanTimer() {
        self.resetTimer?.invalidate()
        self.resetTimer = nil
    }
    
    
    func moveClipContentToCenter() {
        let maxClipRect = self.maxClipFrame
        var clipRect = self.clipBoxFrame
        
        if clipRect.width < CGFloat.ulpOfOne || clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let scale = min(maxClipRect.width/clipRect.width, maxClipRect.height/clipRect.height)
        
        let focusPoint = CGPoint(x: clipRect.midX, y: clipRect.midY)
        let midPoint = CGPoint(x: maxClipRect.midX, y: maxClipRect.midY)
        
        clipRect.size.width = ceil(clipRect.width * scale)
        clipRect.size.height = ceil(clipRect.height * scale)
        clipRect.origin.x = maxClipRect.minX + ceil((maxClipRect.width-clipRect.width)/2)
        clipRect.origin.y = maxClipRect.minY + ceil((maxClipRect.height-clipRect.height)/2)
        
        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = (focusPoint.x + self.scrollView.contentOffset.x) * scale
        contentTargetPoint.y = (focusPoint.y + self.scrollView.contentOffset.y) * scale
        
        var offset = CGPoint(x: contentTargetPoint.x - midPoint.x, y: contentTargetPoint.y - midPoint.y)
        offset.x = max(-clipRect.minX, offset.x)
        offset.y = max(-clipRect.minY, offset.y)
        
        UIView.animate(withDuration: 0.3) {
            if scale < 1 - CGFloat.ulpOfOne || scale > 1 + CGFloat.ulpOfOne {
                self.scrollView.zoomScale *= scale
                self.scrollView.zoomScale = min(self.scrollView.maximumZoomScale, self.scrollView.zoomScale)
            }

            if self.scrollView.zoomScale < self.scrollView.maximumZoomScale - CGFloat.ulpOfOne {
                offset.x = min(self.scrollView.contentSize.width-clipRect.maxX, offset.x)
                offset.y = min(self.scrollView.contentSize.height-clipRect.maxY, offset.y)
                self.scrollView.contentOffset = offset
            }
            self.rotateBtn.alpha = 1
            self.shadowView.alpha = 1
            self.changeClipBoxFrame(newFrame: clipRect)
        }
    }
    
    func clipImage() -> UIImage {
        let imageSize = self.editImage.size
        let contentSize = self.scrollView.contentSize
        let offset = self.scrollView.contentOffset
        let insets = self.scrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(self.clipBoxFrame.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(self.clipBoxFrame.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        
        let origin = CGPoint(x: -frame.minX, y: -frame.minY)
        UIGraphicsBeginImageContextWithOptions(frame.size, false, self.editImage.scale)
        self.editImage.draw(at: origin)
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return self.editImage
        }
        let newImage = UIImage(cgImage: cgi, scale: self.editImage.scale, orientation: .up)
        return newImage
    }
    
}


extension ZLClipImageViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.gridPanGes else {
            return true
        }
        let point = gestureRecognizer.location(in: self.view)
        let frame = self.overlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
    
}


extension ZLClipImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.startEditing()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.startEditing()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.startTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.startTimer()
        }
    }
    
}



class ZLClipShadowView: UIView {
    
    var clearRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor(white: 0, alpha: 0.7).setFill()
        UIRectFill(rect)
        let cr = self.clearRect.intersection(rect)
        UIColor.clear.setFill()
        UIRectFill(cr)
    }
    
}



// MARK: 裁剪网格视图
class ZLClipOverlayView: UIView {
    
    static let cornerLineWidth: CGFloat = 3
    
    var cornerBoldLines: [UIView] = []
    
    var velLines: [UIView] = []
    
    var horLines: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.clipsToBounds = false
        // 两种方法实现裁剪框，drawrect动画效果 更好一点
//        func line(_ isCorner: Bool) -> UIView {
//            let line = UIView()
//            line.backgroundColor = .white
//            line.layer.shadowColor  = UIColor.black.cgColor
//            if !isCorner {
//                line.layer.shadowOffset = .zero
//                line.layer.shadowRadius = 1.5
//                line.layer.shadowOpacity = 0.8
//            }
//            self.addSubview(line)
//            return line
//        }
//
//        (0..<8).forEach { (_) in
//            self.cornerBoldLines.append(line(true))
//        }
//
//        (0..<4).forEach { (_) in
//            self.velLines.append(line(false))
//            self.horLines.append(line(false))
//        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
//        let borderLineLength: CGFloat = 20
//        let borderLineWidth: CGFloat = ZLClipOverlayView.cornerLineWidth
//        for (i, line) in self.cornerBoldLines.enumerated() {
//            switch i {
//            case 0:
//                // 左上 hor
//                line.frame = CGRect(x: -borderLineWidth, y: -borderLineWidth, width: borderLineLength, height: borderLineWidth)
//            case 1:
//                // 左上 vel
//                line.frame = CGRect(x: -borderLineWidth, y: -borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 2:
//                // 右上 hor
//                line.frame = CGRect(x: self.bounds.width-borderLineLength+borderLineWidth, y: -borderLineWidth, width: borderLineLength, height: borderLineWidth)
//            case 3:
//                // 右上 vel
//                line.frame = CGRect(x: self.bounds.width, y: -borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 4:
//                // 左下 hor
//                line.frame = CGRect(x: -borderLineWidth, y: self.bounds.height, width: borderLineLength, height: borderLineWidth)
//            case 5:
//                // 左下 vel
//                line.frame = CGRect(x: -borderLineWidth, y: self.bounds.height-borderLineLength+borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 6:
//                // 右下 hor
//                line.frame = CGRect(x: self.bounds.width-borderLineLength+borderLineWidth, y: self.bounds.height, width: borderLineLength, height: borderLineWidth)
//            case 7:
//                line.frame = CGRect(x: self.bounds.width, y: self.bounds.height-borderLineLength+borderLineWidth, width: borderLineWidth, height: borderLineLength)
//
//            default:
//                break
//            }
//        }
//
//        let normalLineWidth: CGFloat = 1
//        var x: CGFloat = 0
//        var y: CGFloat = -1
//        // 横线
//        for (index, line) in self.horLines.enumerated() {
//            if index == 0 || index == 3 {
//                x = borderLineLength-borderLineWidth
//            } else  {
//                x = 0
//            }
//            line.frame = CGRect(x: x, y: y, width: self.bounds.width - x * 2, height: normalLineWidth)
//            y += (self.bounds.height + 1) / 3
//        }
//
//        x = -1
//        y = 0
//        // 竖线
//        for (index, line) in self.velLines.enumerated() {
//            if index == 0 || index == 3 {
//                y = borderLineLength-borderLineWidth
//            } else  {
//                y = 0
//            }
//            line.frame = CGRect(x: x, y: y, width: normalLineWidth, height: self.bounds.height - y * 2)
//            x += (self.bounds.width + 1) / 3
//        }
        
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(1)

        context?.beginPath()
        var dw: CGFloat = 3
        for _ in 0..<4 {
            context?.move(to: CGPoint(x: rect.origin.x+dw, y: rect.origin.y+3))
            context?.addLine(to: CGPoint(x: rect.origin.x+dw, y: rect.origin.y+rect.height-3))
            dw += (rect.size.width - 6) / 3
        }

        var dh: CGFloat = 3
        for _ in 0..<4 {
            context?.move(to: CGPoint(x: rect.origin.x+3, y: rect.origin.y+dh))
            context?.addLine(to: CGPoint(x: rect.origin.x+rect.width-3, y: rect.origin.y+dh))
            dh += (rect.size.height - 6) / 3
        }

        context?.strokePath()

        context?.setLineWidth(3)

        let boldLineLength: CGFloat = 20
        // 左上
        context?.move(to: CGPoint(x: 0, y: 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: 1.5))

        context?.move(to: CGPoint(x: 1.5, y: 0))
        context?.addLine(to: CGPoint(x: 1.5, y: boldLineLength))

        // 右上
        context?.move(to: CGPoint(x: rect.width-boldLineLength, y: 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: 1.5))

        context?.move(to: CGPoint(x: rect.width-1.5, y: 0))
        context?.addLine(to: CGPoint(x: rect.width-1.5, y: boldLineLength))

        // 左下
        context?.move(to: CGPoint(x: 1.5, y: rect.height-boldLineLength))
        context?.addLine(to: CGPoint(x: 1.5, y: rect.height))

        context?.move(to: CGPoint(x: 0, y: rect.height-1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: rect.height-1.5))

        // 右下
        context?.move(to: CGPoint(x: rect.width-boldLineLength, y: rect.height-1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: rect.height-1.5))

        context?.move(to: CGPoint(x: rect.width-1.5, y: rect.height-boldLineLength))
        context?.addLine(to: CGPoint(x: rect.width-1.5, y: rect.height))

        context?.strokePath()

        context?.setShadow(offset: CGSize(width: 1, height: 1), blur: 0)
    }
    
}
