/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import DatadogInternal

class OTelHTTPHeadersReaderTests: XCTestCase {
    func testOTelHTTPHeadersReaderreadsSingleHeader() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: ["b3": "4d2-929-1-162e"])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertEqual(ids?.traceID, 1_234)
        XCTAssertEqual(ids?.spanID, 2_345)
        XCTAssertEqual(ids?.parentSpanID, 5_678)
    }

    func testOTelHTTPHeadersReaderreadsSingleHeaderWithSampling() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: ["b3": "0"])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertNil(ids?.traceID)
        XCTAssertNil(ids?.spanID)
        XCTAssertNil(ids?.parentSpanID)
    }

    func testOTelHTTPHeadersReaderreadsSingleHeaderWithoutOptionalValues() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: ["b3": "4d2-929"])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertEqual(ids?.traceID, 1_234)
        XCTAssertEqual(ids?.spanID, 2_345)
        XCTAssertNil(ids?.parentSpanID)
    }

    func testOTelHTTPHeadersReaderreadsMultipleHeader() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: [
            "X-B3-TraceId": "4d2",
            "X-B3-SpanId": "929",
            "X-B3-Sampled": "1",
            "X-B3-ParentSpanId": "162e"
        ])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertEqual(ids?.traceID, 1_234)
        XCTAssertEqual(ids?.spanID, 2_345)
        XCTAssertEqual(ids?.parentSpanID, 5_678)
    }

    func testOTelHTTPHeadersReaderreadsMultipleHeaderWithSampling() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: [
            "X-B3-Sampled": "0"
        ])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertNil(ids?.traceID)
        XCTAssertNil(ids?.spanID)
        XCTAssertNil(ids?.parentSpanID)
    }

    func testOTelHTTPHeadersReaderreadsMultipleHeaderWithoutOptionalValues() {
        let oTelHTTPHeadersReader = OTelHTTPHeadersReader(httpHeaderFields: [
            "X-B3-TraceId": "4d2",
            "X-B3-SpanId": "929"
        ])

        let ids = oTelHTTPHeadersReader.read()

        XCTAssertEqual(ids?.traceID, 1_234)
        XCTAssertEqual(ids?.spanID, 2_345)
        XCTAssertNil(ids?.parentSpanID)
    }
}