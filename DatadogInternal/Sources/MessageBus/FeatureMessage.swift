/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

/// The set of messages that can be transimtted on the Features message bus.
public enum FeatureMessage {
    /// A custom message with generic encodable
    /// attributes.
    case baggage(
        label: String,
        baggage: NewFeatureBaggage
    )

    /// A core context message.
    ///
    /// The core will send updated context throught the bus. Do not send new context values
    /// from a Feature or Integration.
    case context(DatadogContext)

    /// A telemtry message.
    ///
    /// The core can send telemtry data coming from all Features.
    case telemetry(TelemetryMessage)
}

extension FeatureMessage {
    /// Creates a `.baggage` message with thegiven label and `Encodable` type.
    ///
    /// - Parameters:
    ///   - label: The baggage label.
    ///   - baggage: The baggage value.
    /// - Returns: a `.baggage` case.
    public static func baggage<Value>(label: String, value: Value) throws -> FeatureMessage where Value: Encodable {
        try .baggage(label: label, baggage: .init(value))
    }

    /// Decodes the value of a baggage if the label matches.
    ///
    /// - Parameters:
    ///   - label: The requested baggage label.
    ///   - type: The expected type of the baggage value.
    /// - Returns: The decoded baggage value, or nil if the label doesn't match.
    /// - Throws: A `DecodingError` if decoding fails.
    public func baggage<Value>(label: String, type: Value.Type = Value.self) throws -> Value? where Value: Decodable {
        guard case let .baggage(_label, baggage) = self, _label == label else {
            return nil
        }

        return try baggage.decode(type: type)
    }
}
