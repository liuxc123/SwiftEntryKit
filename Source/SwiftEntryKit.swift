//
//  SwiftEntryKit.swift
//  SwiftEntryKit
//
//  Created by Daniel Huri on 4/29/18.
//

import UIKit

/**
 A stateless, threadsafe (unless described otherwise) entry point that contains the display and the dismissal logic of entries.
 */
public final class SwiftEntryKit {
    
    /** Describes the a single or multiple entries for possible dismissal states */
    public enum EntryDismissalDescriptor {
        
        /** Describes specific entry / entries with name */
        case specific(entryName: String)
        
        /** Describes a group of entries with lower or equal display priority */
        case prioritizedLowerOrEqualTo(priority: EKAttributes.Precedence.Priority)
        
        /** Describes all the entries that are currently in the queue and pending presentation */
        case enqueued
        
        /** Describes all the entries */
        case all
        
        /** Describes the currently displayed entry */
        case displayed
    }
    
    /** The window to rollback to after dismissal */
    public enum RollbackWindow {
        
        /** The main window */
        case main
        
        /** A given custom window */
        case custom(window: UIWindow)
    }
    
    /** Completion handler for the dismissal method */
    public typealias DismissCompletionHandler = () -> Void
    
    /** Cannot be instantiated, customized, inherited. */
    private init() {}
    
    /**
     Returns the window that displays the entry.
     **Warning**: the returned `UIWindow` instance is `nil` in case
     no entry is currently displayed.
     This can be used
     */
    public class var window: UIWindow? {
        return EKWindowProvider.shared.entryWindow
    }
        
    /**
     Returns true if an entry with a given name is currently displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed.
     - Returns a *false* value for currently enqueued entries.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.isCurrentlyDisplaying(entryNamed: name)
    }
    
    /**
     Returns true if an entry with a given name is currently displayed on a view.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed.
     - Returns a *false* value for currently enqueued entries.
     - parameter name: The name of the entry. Its default value is *nil*.
     - parameter provider: The entry view provider.
     */
    public class func isCurrentlyDisplaying(entryNamed name: String? = nil, from provider: EKViewProvider) -> Bool {
        return provider.isCurrentlyDisplaying(entryNamed: name)
    }
    
    /**
     Returns true if **any** entry is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **~queueContains() -> Bool** (witohut the name of the entry)
     */
    public class func isQueueEmpty() -> Bool {
        return !queueContains()
    }
    
    /**
     Returns true if **any** entry is currently enqueued and waiting to be displayed on a view.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **~queueContains() -> Bool** (witohut the name of the entry)
     */
    public class func isQueueEmpty(from provider: EKViewProvider) -> Bool {
        return !queueContains(from: provider)
    }
    
    /**
     Returns true if an entry with a given name is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed, meaning, the queue is not currently empty.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func queueContains(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.queueContains(entryNamed: name)
    }
    
    /**
     Returns true if an entry with a given name is currently enqueued and waiting to be displayed on a view.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed, meaning, the queue is not currently empty.
     - parameter name: The name of the entry. Its default value is *nil*.
     - parameter provider: The entry view provider.
     */
    public class func queueContains(entryNamed name: String? = nil, from provider: EKViewProvider) -> Bool {
        return provider.queueContains(entryNamed: name)
    }
    
    /**
     Displays a given entry view using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* which is the app main window
     */
    public class func display(entry view: UIView, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(view: view, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    /**
     Displays a given entry view using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentView: Display on the view
     - parameter presentInMainProivder: Display on the main provider.
     */
    public class func display(entry view: UIView, using attributes: EKAttributes, presentView: UIView, presentInMainProivder: Bool = true) {
        DispatchQueue.main.async {
            var provider: EKViewProvider!
            if presentInMainProivder {
                provider = presentView.mainProvider
            } else {
                provider = EKViewProvider(presentView: presentView)
                provider.appendToPresentView()
            }
            view.entryProvider = provider
            let entryView = EKEntryView(newEntry: .init(view: view, attributes: attributes))
            provider.display(entryView: entryView, using: attributes)
        }
    }
    
    /**
     Displays a given entry view controller using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* - which is the app main window
     */
    public class func display(entry viewController: UIViewController, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(viewController: viewController, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    /**
     Displays a given entry view controller using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter viewController: Custom viewController that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter presentView: Display on the view.
     - parameter presentInMainProivder: Display on the main provider.
     */
    public class func display(entry viewController: UIViewController, using attributes: EKAttributes, presentView: UIView, presentInMainProivder: Bool = true) {
        DispatchQueue.main.async {
            var provider: EKViewProvider!
            if presentInMainProivder {
                provider = presentView.mainProvider
            } else {
                provider = EKViewProvider(presentView: presentView)
                provider.appendToPresentView()
            }
            viewController.view.entryProvider = provider
            let entryView = EKEntryView(newEntry: .init(viewController: viewController, attributes: attributes))
            provider.display(entryView: entryView, using: attributes)
        }
    }
    
    /**
     ALPHA FEATURE: Transform the previous entry to the current one using the previous attributes struct.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - This feature hasn't been fully tested. Use with caution.
     - parameter view: Custom view that is to be displayed instead of the currently displayed entry
     */
    public class func transform(to view: UIView) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.transform(to: view)
        }
    }
    
    /**
     ALPHA FEATURE: Transform the previous entry to the current one using the previous attributes struct.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - This feature hasn't been fully tested. Use with caution.
     - parameter view: Custom view that is to be displayed instead of the currently displayed entry
     - parameter provider: The entry view provider.
     */
    public class func transform(to view: UIView, from provider: EKViewProvider?) {
        DispatchQueue.main.async {
            provider?.transform(to: view)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented window instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(_ descriptor: EntryDismissalDescriptor = .displayed, with completion: DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.dismiss(descriptor, with: completion)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented window instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter view: The entry view.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(entry view: UIView?, descriptor: SwiftEntryKit.EntryDismissalDescriptor = .displayed, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            view?.entryProvider?.dismiss(descriptor, with: completion)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented window instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter viewController: The entry view controller.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(entry viewController: UIViewController?, descriptor: SwiftEntryKit.EntryDismissalDescriptor = .displayed, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            viewController?.view.entryProvider?.dismiss(descriptor, with: completion)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented view instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter presentView: Display on the view.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(form presentView: UIView?, descriptor: SwiftEntryKit.EntryDismissalDescriptor = .displayed) {
        DispatchQueue.main.async {
            presentView?.viewProviders.forEach({ $0.dismiss(descriptor, with: nil) })
        }
    }
    
    /**
     Layout the view hierarchy that is rooted in the window.
     - In case you use complex animations, you can call it to refresh the AutoLayout mechanism on the entire view hierarchy.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     */
    public class func layoutIfNeeded() {
        if Thread.isMainThread {
            EKWindowProvider.shared.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                EKWindowProvider.shared.layoutIfNeeded()
            }
        }
    }
    
    /**
     Layout the view hierarchy that is rooted in the view.
     - In case you use complex animations, you can call it to refresh the AutoLayout mechanism on the entire view hierarchy.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter view: The entry view.
     */
    public class func layoutIfNeeded(entry view: UIView?) {
        if Thread.isMainThread {
            view?.entryProvider?.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                view?.entryProvider?.layoutIfNeeded()
            }
        }
    }
    
    /**
     Layout the view hierarchy that is rooted in the view.
     - In case you use complex animations, you can call it to refresh the AutoLayout mechanism on the entire view hierarchy.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter viewController: The entry view controller.
     */
    public class func layoutIfNeeded(entry viewController: UIViewController?) {
        if Thread.isMainThread {
            viewController?.view.entryProvider?.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                viewController?.view.entryProvider?.layoutIfNeeded()
            }
        }
    }

    /**
     Get all providers from presentView.
     - parameter presentView: The present view.
     */
    public class func providers(from presentView: UIView?) -> [EKViewProvider] {
        return presentView?.viewProviders ?? []
    }
    
    /**
     Get provider from entry view.
     - parameter viewController: The entry view controller.
     */
    public class func provider(from viewController: UIViewController?) -> EKViewProvider? {
        return viewController?.view.entryProvider
    }
    
    /**
     Get provider from entry view.
     - parameter view: The entry view.
     */
    public class func provider(from view: UIView?) -> EKViewProvider? {
        return view?.entryProvider
    }
}
