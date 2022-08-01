//
//  EKViewProvider.swift
//  SwiftEntryKit
//
//  Created by liuxc on 2022/8/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

public final class EKViewProvider: NSObject, EntryPresenterDelegate {

    /** Current entry presentView */
    public weak var presentView: UIView!

    /** Current entry view */
    private var entryView: EKEntryView!

    /** Current root controller */
    private var entryVC: EKRootViewController?
    
    /** Entry queueing heuristic  */
    private let entryQueue = EKAttributes.Precedence.QueueingHeuristic.value.heuristic

    /** Cannot be instantiated, customized, inherited */
    init(presentView: UIView) {
        self.presentView = presentView
        super.init()
    }

    var isResponsiveToTouches: Bool = false

    // MARK: - Setup and Teardown methods

    // Prepare the view and the host view controller
    private func prepare(for attributes: EKAttributes) -> EKRootViewController? {
        if entryVC == nil {
            entryVC = EKRootViewController(with: self)
        }
        entryVC!.setStatusBarStyle(for: attributes)
        presentView.addSubview(entryVC!.view)
        entryVC?.view.fillSuperview()

        return entryVC
    }
    
    /** Transform current entry to view */
    func transform(to view: UIView) {
        entryView?.transform(to: view)
    }
    
    /**
     Privately used to display an entry
     */
    func display(entryView: EKEntryView, using attributes: EKAttributes) {
        switch entryView.attributes.precedence {
        case .override(priority: _, dropEnqueuedEntries: let dropEnqueuedEntries):
            if dropEnqueuedEntries {
                entryQueue.removeAll()
            }
            show(entryView: entryView)
        case .enqueue where isCurrentlyDisplaying():
            entryQueue.enqueue(entry: .init(view: entryView))
        case .enqueue:
            show(entryView: entryView)
        }
    }
    
    // MARK: - Exposed Actions

    func queueContains(entryNamed name: String? = nil) -> Bool {
        if name == nil && !entryQueue.isEmpty {
            return true
        }
        if let name = name {
            return entryQueue.contains(entryNamed: name)
        } else {
            return false
        }
    }

    /**
     Returns *true* if the currently displayed entry has the given name.
     In case *name* has the value of *nil*, the result is *true* if any entry is currently displayed.
     */
    func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        guard let entryView = entryView else {
            return false
        }
        if let name = name { // Test for names equality
            return entryView.content.attributes.name == name
        } else { // Return true by default if the name is *nil*
            return true
        }
    }
    
    /** clear current entry view */
    private func removeFromPresentView() {
        entryVC?.view.removeFromSuperview()
        entryVC = nil
        entryView = nil
        presentView.providers.removeAll { [weak self] (provider) -> Bool in
            guard let self = self else { return false }
            return provider == self
        }
    }
    
    /** Add to presentView */
    func appendToPresentView() {
        if !self.presentView.providers.contains(self) {
            self.presentView.providers.append(self)
        }
    }
    
    func displayPendingEntryOrRollbackWindow(dismissCompletionHandler: SwiftEntryKit.DismissCompletionHandler?) {
        
        if let next = entryQueue.dequeue() {

            // Execute dismiss handler if needed before dequeuing (potentially) another entry
            dismissCompletionHandler?()

            // Show the next entry in queue
            show(entryView: next.view)
        } else {

            // Display the rollback window
            removeFromPresentView()

            // As a last step, invoke the dismissal method
            dismissCompletionHandler?()
        }
    }
    
    /** Dismiss entries according to a given descriptor */
    func dismiss(_ descriptor: SwiftEntryKit.EntryDismissalDescriptor, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        guard let entryVC = entryVC else {
            return
        }

        switch descriptor {
        case .displayed:
            entryVC.animateOutLastEntry(completionHandler: completion)
        case .specific(entryName: let name):
            entryQueue.removeEntries(by: name)
            if entryView?.attributes.name == name {
                entryVC.animateOutLastEntry(completionHandler: completion)
            }
        case .prioritizedLowerOrEqualTo(priority: let priorityThreshold):
            entryQueue.removeEntries(withPriorityLowerOrEqualTo: priorityThreshold)
            if let currentPriority = entryView?.attributes.precedence.priority, currentPriority <= priorityThreshold {
                entryVC.animateOutLastEntry(completionHandler: completion)
            }
        case .enqueued:
            entryQueue.removeAll()
        case .all:
            entryQueue.removeAll()
            entryVC.animateOutLastEntry(completionHandler: completion)
        }
    }

    /** Layout the view-hierarchy rooted in the window */
    func layoutIfNeeded() {
        presentView?.layoutIfNeeded()
    }
    
    /** Privately used to prepare the root view controller and show the entry immediately */
    private func show(entryView: EKEntryView) {
        guard let entryVC = prepare(for: entryView.attributes) else {
            return
        }
        entryVC.configure(entryView: entryView)
        self.entryVC = entryVC
        self.entryView = entryView
    }
}





