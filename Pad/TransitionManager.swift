//
//  TransitionManager.swift
//  Pad
//
//  Created by Colin Dunn on 4/11/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit

class TransitionManger: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning {
    
    var isPresenting = false
    var interactiveTransition: UIPercentDrivenInteractiveTransition!
    var presentingController: UIViewController! {
        didSet {
            self.pinchGesture = UIPinchGestureRecognizer(target: self, action: "onPinch:")
            self.presentingController.view.addGestureRecognizer(self.pinchGesture)
        }
    }
    
    private var isInteractive = false
    private var pinchGesture = UIPinchGestureRecognizer()
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        
        if isPresenting {
            containerView.addSubview(toViewController!.view)
            toViewController?.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
                toViewController?.view.transform = CGAffineTransformMakeScale(1, 1)
                
                }) { (finished: Bool) -> Void in
                    transitionContext.completeTransition(true)
            }
        } else {
            UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
                fromViewController?.view.transform = CGAffineTransformMakeScale(0.01, 0.01)
                
                }) { (finished: Bool) -> Void in
                    if transitionContext.transitionWasCancelled() {
                        transitionContext.completeTransition(false)
                    } else {
                        transitionContext.completeTransition(true)
                        fromViewController?.view.removeFromSuperview()
                    }
            }
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactiveTransition = UIPercentDrivenInteractiveTransition()
        return isInteractive ? self : nil
    }
    
    func onPinch(sender: UIPinchGestureRecognizer) {
        switch (sender.state) {
        case UIGestureRecognizerState.Began:
            isInteractive = true
            presentingController.dismissViewControllerAnimated(true, completion: nil)
            break
            
        case UIGestureRecognizerState.Changed:
            updateInteractiveTransition(1 - sender.scale)
            break
            
        default:
            if sender.scale < 0.5 {
                isInteractive = false
                finishInteractiveTransition()
            } else {
                cancelInteractiveTransition()
            }
        }
    }
}