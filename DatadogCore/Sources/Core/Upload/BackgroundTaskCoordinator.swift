/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

/// The `BackgroundTaskCoordinator` protocol provides an abstraction for managing background tasks and includes methods for registering and ending background tasks.
/// It serves as a useful abstraction for testing purposes as well as allows decoupling from UIKit in order to maintain Catalyst compliation. To abstract from UIKit, it leverages
/// the fact that UIBackgroundTaskIdentifier raw value is based on Int.
internal protocol BackgroundTaskCoordinator {
    func registerBackgroundTask(expirationHandler handler: @escaping (() -> Void)) -> Int
    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: Int)
}

#if canImport(UIKit)
import UIKit

/// Manages background tasks using UIKit.
/// This coordinator conforms to the `BackgroundTaskCoordinator` protocol and provides an implementation of managing background tasks using the UIKit framework.
/// It allows for registering and ending background tasks.
internal class UIKitBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    internal func registerBackgroundTask(expirationHandler handler: @escaping (() -> Void)) -> Int {
        guard let app = UIApplication.dd.managedShared else {
            return UIBackgroundTaskIdentifier.invalid.rawValue
        }
        return app.beginBackgroundTask(expirationHandler: handler).rawValue
    }

    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: Int) {
        let task = UIBackgroundTaskIdentifier(rawValue: backgroundTaskIdentifier)
        guard task != .invalid else {
            return
        }
        UIApplication.dd.managedShared?.endBackgroundTask(task)
    }
}
#endif
