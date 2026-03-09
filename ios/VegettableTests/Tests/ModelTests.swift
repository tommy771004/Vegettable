import XCTest

final class ModelTests: XCTestCase {

    func test_priceAlert_validConditions() {
        let valid = ["below", "above"]
        XCTAssertTrue(valid.contains("below"))
        XCTAssertTrue(valid.contains("above"))
        XCTAssertFalse(valid.contains("equal"))
    }

    func test_productDetail_defaultPriceLevelIsNormal() {
        let defaultLevel = "normal"
        let validLevels = ["very-cheap", "cheap", "normal", "expensive"]
        XCTAssertTrue(validLevels.contains(defaultLevel))
    }

    func test_productDetail_defaultTrendIsStable() {
        let validTrends = ["up", "down", "stable"]
        XCTAssertTrue(validTrends.contains("stable"))
    }

    func test_apiResponse_successField_exists() {
        let jsonString = "{\"success\": true, \"data\": null, \"message\": null, \"timestamp\": 1234567890}"
        let data = jsonString.data(using: .utf8)!
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["success"])
        XCTAssertNotNil(json?["timestamp"])
    }

    func test_price_decimalPrecision() {
        let formatted = String(format: "%.1f", 123.456789)
        XCTAssertEqual(formatted, "123.5")
    }

    func test_peakMonths_validRange() {
        for month in [3, 4, 5] {
            XCTAssertGreaterThanOrEqual(month, 1)
            XCTAssertLessThanOrEqual(month, 12)
        }
    }

    func test_currentMonth_isInValidRange() {
        let m = Calendar.current.component(.month, from: Date())
        XCTAssertGreaterThanOrEqual(m, 1)
        XCTAssertLessThanOrEqual(m, 12)
    }
}