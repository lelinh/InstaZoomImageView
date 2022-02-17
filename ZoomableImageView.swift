//
//  ZoomableImage.swift
//
//  Created by Linh Le Manh on 17/02/2022.
//  Copyright © 2022 All rights reserved.
//

import UIKit

class ZoomableImageView: UIImageView {
    private var zoomImageView = UIImageView()
    private var backgroundZoomView = UIView()
    private var originalParentView: UIView?
    
    override var image: UIImage? {
        didSet {
            zoomImageView.image = image
        }
    }
    
    //MARK: PUBLIC METHODS
    public func configPinchable(with view: UIView?) {
        originalParentView = view
        isPinchable = true
        zoomImageView.contentMode = contentMode
    }
    
        /// Key for associated object
    private struct AssociatedKeys {
        static var ImagePinchKey: Int8 = 0
        static var ImagePinchGestureKey: Int8 = 1
        static var ImagePanGestureKey: Int8 = 2
        static var ImageScaleKey: Int8 = 3
    }
    
    private func updateTheFrame() {
        if let frame_ = originalParentView?.convert(bounds, to: nil) {
            let screenBounds = UIScreen.main.bounds
            
            zoomImageView.frame = frame_
            backgroundZoomView.frame = screenBounds
//            blurView.frame = CGRect(x: screenBounds.origin.x,
//                                    y: screenBounds.height - screenBounds.height/3,
//                                    width: screenBounds.width,
//                                    height: screenBounds.height/3)
            if let tbView = originalParentView as? UITableView {
                tbView.isScrollEnabled = false
            }
        }
    }
    
        /// The image should zoom on Pinch
    private var isPinchable: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ImagePinchKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImagePinchKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            
            if pinchGesture == nil {
                inititialize()
            }
            
            if newValue {
                isUserInteractionEnabled = true
                pinchGesture.map { addGestureRecognizer($0) }
                panGesture.map { addGestureRecognizer($0) }
            } else {
                pinchGesture.map { removeGestureRecognizer($0) }
                panGesture.map { removeGestureRecognizer($0) }
            }
        }
    }
    
        /// Associated image's pinch gesture
    private var pinchGesture: UIPinchGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ImagePinchGestureKey) as? UIPinchGestureRecognizer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImagePinchGestureKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
        /// Associated image's pan gesture
    private var panGesture: UIPanGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ImagePanGestureKey) as? UIPanGestureRecognizer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImagePanGestureKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
        /// Associated image's scale -- there might be no need
    private var scale: CGFloat {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.ImageScaleKey) as? CGFloat) ?? 1.0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImageScaleKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    
        /// Initialize pinch & pan gestures
    private func inititialize() {
        //
        let topVc = UIApplication.shared.keyWindow

        let frame_ = originalParentView?.convert(bounds, to: topVc) ?? .zero

        let screenBounds = UIScreen.main.bounds
        zoomImageView = UIImageView()
        zoomImageView.image = image
        zoomImageView.backgroundColor = .clear
        zoomImageView.clipsToBounds = false
        zoomImageView.contentMode = .scaleAspectFill
        zoomImageView.frame = frame_
        zoomImageView.isUserInteractionEnabled = false
        zoomImageView.alpha = 0

        backgroundZoomView = UIView(frame: screenBounds)
        backgroundZoomView.backgroundColor = .black
        backgroundZoomView.alpha = 0
        backgroundZoomView.isUserInteractionEnabled = false
        
        topVc?.addSubview(backgroundZoomView)
        topVc?.addSubview(zoomImageView)

            //
        pinchGesture = UIPinchGestureRecognizer(
            target: self,
            action: #selector(imagePinched(_:)))
        pinchGesture?.delegate = self
        panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(imagePanned(_:)))
        panGesture?.delegate = self
    }
    
        /// Perform the pinch to zoom if needed.
        ///
        /// - Parameter sender: UIPinvhGestureRecognizer
    @objc private func imagePinched(_ pinch: UIPinchGestureRecognizer) {
        if pinch.state == .began { updateTheFrame() }
        if pinch.scale >= 1.0 {
            scale = pinch.scale
            transform(withTranslation: .zero)
        }
        
        if pinch.state != .ended { return }
        
        reset()
    }
    
        /// Perform the panning if needed
        ///
        /// - Parameter sender: UIPanGestureRecognizer
    @objc private func imagePanned(_ pan: UIPanGestureRecognizer) {
        if scale > 1.0 {
            transform(withTranslation: pan.translation(in: zoomImageView))
        }
        
        if pan.state != .ended { return }
        
        reset()
    }
    
        /// Set the image back to it's initial state.
    private func reset() {
        scale = 1.0
        self.alpha = 1
        
        self.backgroundZoomView.alpha = min(backgroundZoomView.alpha, 0.5)
        if let tbView = originalParentView as? UITableView {
            tbView.isScrollEnabled = true
        }
        UIView.animate(withDuration: 0.3) {
            self.zoomImageView.transform = .identity
            self.transform = .identity
            self.backgroundZoomView.alpha = 0
            self.zoomImageView.alpha = 0
        }
    }
    
        /// Will transform the image with the appropriate
        /// scale or translation.
        ///
        /// Parameter translation: CGPoint
    private func transform(withTranslation translation: CGPoint) {
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, scale, scale, 1.01)
        transform = CATransform3DTranslate(transform, translation.x, translation.y, 0)
        self.zoomImageView.layer.transform = transform
        layer.transform = transform
        self.backgroundZoomView.alpha = min(9, scale*scale)/9
        self.zoomImageView.alpha = 1
        self.alpha = 0
    }
}

extension ZoomableImageView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
