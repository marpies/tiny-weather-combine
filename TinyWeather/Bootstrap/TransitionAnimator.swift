//
//  TransitionAnimator.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import UIKit

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let pushing: Bool
    
    init(pushing: Bool) {
        self.pushing = pushing
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.pushing ? 1 : 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let duration: TimeInterval = transitionDuration(using: transitionContext)
        let size: CGSize = fromView.frame.size
        
        let container: UIView = transitionContext.containerView
        if self.pushing {
            container.insertSubview(toView, aboveSubview: fromView)
        } else {
            container.insertSubview(toView, belowSubview: fromView)
        }
        
        if self.pushing {
            toView.center = CGPoint(x: size.width / 2, y: size.height / 2)
            toView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            toView.alpha = 0
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                toView.center = CGPoint(x: size.width / 2, y: size.height / 2)
                toView.alpha = 1
                toView.transform = .identity
            }) { (_) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            toView.center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                fromView.alpha = 0
                fromView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { (_) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
