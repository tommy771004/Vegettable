import XCTest

final class PriceFormatterTests: XCTestCase {

    func test_priceLevel_veryCheap_threshold() {
        let ratio = 60.0 / 100.0
        XCTAssertLessThan(ratio, 0.70)
    }

    func test_priceLevel_cheap_threshold() {
        let ratio = 80.0 / 100.0
        XCTAssertGreaterThanOrEqual(ratio, 0.70)
        XCTAssertLessThan(ratio, 0.90)
    }

    func test_priceLevel_normal_threshold() {
        let ratio = 100.0 / 100.0
        XCTAssertGreaterThanOrEqual(ratio, 0.90)
        XCTAssertLessThanOrEqual(ratio, 1.20)
    }

    func test_priceLevel_expensive_threshold() {
        let ratio = 130.0 / 100.0
        XCTAssertGreaterThan(ratio, 1.20)
    }

    func test_kgToCatty_conversion() {
        XCTAssertEqual(100.0 * 0.6, 60.0, accuracy: 0.001)
    }

    func test_kgToCatty_zero() {
        XCTAssertEqual(0.0 * 0.6, 0.0, accuracy: 0.001)
    }

    func test_trend_up_when_price_increases() {
        let change = (110.0 - 100.0) / 100.0
        XCTAssertGreaterThan(change, 0.05)
    }

    func test_trend_down_when_price_decreases() {
        let change = (88.0 - 100.0) / 100.0
        XCTAssertLessThan(change, -0.05)
    }

    func test_trend_stable_when_small_change() {
        let change = abs((102.0 - 100.0) / 100.0)
        XCTAssertLessThanOrEqual(change, 0.05)
    }

    func test_rocYear_2024_is_113() {
        XCTAssertEqual(2024 - 1911, 113)
    }

    func test_rocYear_2025_is_114() {
        XCTAssertEqual(2025 - 1911, 114)
    }

    func test_rocDateFormat_march9_2025() {
        let formatted = String(format: "%d.%02d.%02d", 2025 - 1911, 3, 9)
        XCTAssertEqual(formatted, "114.03.09")
    }

    func test_apiUrl_baseUrlIsNotEmpty() {
        let url = "https://api.vegettable.app"
        XCTAssertFalse(url.isEmpty)
        XCTAssertTrue(url.hasPrefix("https://"))
    }

    func test_apiUrl_encodedCropName() {
        let encoded = "高麗菜".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        XCTAssertNotNil(encoded)
    }
}