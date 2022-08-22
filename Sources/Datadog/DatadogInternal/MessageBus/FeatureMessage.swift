/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// The set of messages that can be transimtted on the Features message bus.
public enum FeatureMessage {
    /// An error message.
    case error(
        message: String,
        attributes: FeatureMessageAttributes
    )

    /// An encodable event that will be transmitted
    /// as-is through a Feature.
    case event(
        target: String,
        event: FeatureMessageAttributes.AnyEncodable
    )

    /// A custom message with generic encodable
    /// attributes.
    case custom(
        key: String,
        attributes: FeatureMessageAttributes
    )
}
