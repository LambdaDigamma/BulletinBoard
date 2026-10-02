import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class BulletinLayoutRegionTests: XCTestCase {

    func testNoActiveDivisionKeepsAvailableBounds() {
        let available = CGRect(x: 48, y: 32, width: 700, height: 650)
        let divisions = [
            CGRect.zero,
            CGRect.null,
            CGRect(x: 760, y: 0, width: 24, height: 800),
            CGRect(x: 0, y: 700, width: 800, height: 24),
        ]

        XCTAssertEqual(BulletinLayoutRegion.regions(in: available, excluding: []), [available])
        XCTAssertEqual(BulletinLayoutRegion.regions(in: available, excluding: divisions), [available])
        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: divisions,
                                                   layoutDirection: .leftToRight), available)
    }

    func testEmptyAvailableBoundsHaveNoRegion() {
        for available in [CGRect.zero, CGRect.null,
                          CGRect(x: 20, y: 10, width: 500, height: 0)] {
            XCTAssertTrue(BulletinLayoutRegion.regions(in: available, excluding: []).isEmpty)
            XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [],
                                                       layoutDirection: .leftToRight), .zero)
        }
    }

    func testDivisionThatCoversAllAvailableSpaceHasNoRegion() {
        let available = CGRect(x: 40, y: 30, width: 300, height: 450)
        let division = CGRect(x: 0, y: 0, width: 600, height: 800)

        XCTAssertTrue(BulletinLayoutRegion.regions(in: available, excluding: [division]).isEmpty)
        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .leftToRight), .zero)
    }

    func testVerticalBandLeavesTwoSeparatePanes() {
        let available = CGRect(x: 10, y: 25, width: 780, height: 700)
        let division = CGRect(x: 390, y: -20, width: 28, height: 900)
        let regions = BulletinLayoutRegion.regions(in: available, excluding: [division])

        XCTAssertEqual(regions, [
            CGRect(x: 10, y: 25, width: 380, height: 700),
            CGRect(x: 418, y: 25, width: 372, height: 700),
        ])
        assertClearRegions(regions, within: available, excluding: [division])
    }

    func testHorizontalBandSelectsLowerPaneInBothLayoutDirections() {
        let available = CGRect(x: 24, y: 80, width: 740, height: 760)
        let division = CGRect(x: -30, y: 405, width: 950, height: 24)
        let lowerPane = CGRect(x: 24, y: 429, width: 740, height: 411)
        let regions = BulletinLayoutRegion.regions(in: available, excluding: [division])

        XCTAssertEqual(regions, [
            CGRect(x: 24, y: 80, width: 740, height: 325),
            lowerPane,
        ])
        assertClearRegions(regions, within: available, excluding: [division])
        for direction in [UIUserInterfaceLayoutDirection.leftToRight, .rightToLeft] {
            XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                       layoutDirection: direction), lowerPane)
        }
    }

    func testVerticalBandUsesTrailingPaneInEachLayoutDirection() {
        let available = CGRect(x: 0, y: 0, width: 800, height: 600)
        let division = CGRect(x: 390, y: 0, width: 20, height: 600)

        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .leftToRight),
                       CGRect(x: 410, y: 0, width: 390, height: 600))
        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .rightToLeft),
                       CGRect(x: 0, y: 0, width: 390, height: 600))
    }

    func testAsymmetricAvailableBoundsRemainIntact() {
        let available = CGRect(x: 96, y: 40, width: 604, height: 660)
        let division = CGRect(x: 360, y: 0, width: 24, height: 850)
        let regions = BulletinLayoutRegion.regions(in: available, excluding: [division])

        XCTAssertEqual(regions, [
            CGRect(x: 96, y: 40, width: 264, height: 660),
            CGRect(x: 384, y: 40, width: 316, height: 660),
        ])
        assertClearRegions(regions, within: available, excluding: [division])
    }

    func testMultipleDivisionsSelectOneClearLowerTrailingPane() {
        let available = CGRect(x: 0, y: 0, width: 640, height: 760)
        let divisions = [
            CGRect(x: 280, y: -20, width: 20, height: 800),
            CGRect(x: -20, y: 350, width: 700, height: 30),
        ]
        let regions = BulletinLayoutRegion.regions(in: available, excluding: divisions)

        XCTAssertEqual(regions.count, 4)
        assertClearRegions(regions, within: available, excluding: divisions)
        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: divisions,
                                                   layoutDirection: .leftToRight),
                       CGRect(x: 300, y: 380, width: 340, height: 380))
        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: Array(divisions.reversed()),
                                                   layoutDirection: .rightToLeft),
                       CGRect(x: 0, y: 380, width: 280, height: 380))
    }

    func testPreferredPointKeepsItsPaneAsDivisionMoves() {
        let available = CGRect(x: 0, y: 0, width: 800, height: 600)
        let preferredPoint = CGPoint(x: 190, y: 300)

        for divisionX: CGFloat in [390, 400] {
            let division = CGRect(x: divisionX, y: 0, width: 20, height: 600)
            XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                       layoutDirection: .leftToRight,
                                                       preferredPoint: preferredPoint),
                           CGRect(x: 0, y: 0, width: divisionX, height: 600))
        }
    }

    func testPreferredPointInsideDivisionFallsBackToTrailingPane() {
        let available = CGRect(x: 0, y: 0, width: 800, height: 600)
        let division = CGRect(x: 390, y: 0, width: 20, height: 600)

        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .leftToRight,
                                                   preferredPoint: CGPoint(x: 400, y: 300)),
                       CGRect(x: 410, y: 0, width: 390, height: 600))
    }

    func testKeyboardReducedLowerPaneFallsBackToUpperPane() {
        let division = CGRect(x: 0, y: 360, width: 750, height: 28)
        let fullBounds = CGRect(x: 0, y: 0, width: 750, height: 900)
        let keyboardReducedBounds = CGRect(x: 0, y: 0, width: 750, height: 460)

        XCTAssertEqual(BulletinLayoutRegion.select(in: fullBounds, excluding: [division],
                                                   layoutDirection: .leftToRight),
                       CGRect(x: 0, y: 388, width: 750, height: 512))
        XCTAssertEqual(BulletinLayoutRegion.select(in: keyboardReducedBounds, excluding: [division],
                                                   layoutDirection: .leftToRight,
                                                   preferredPoint: CGPoint(x: 375, y: 430)),
                       CGRect(x: 0, y: 0, width: 750, height: 360))
    }

    func testNarrowTrailingPaneFallsBackToWiderPane() {
        let available = CGRect(x: 0, y: 0, width: 400, height: 500)
        let division = CGRect(x: 260, y: 0, width: 30, height: 500)

        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .leftToRight,
                                                   preferredPoint: CGPoint(x: 330, y: 250)),
                       CGRect(x: 0, y: 0, width: 260, height: 500))
    }

    func testWhenEveryPaneIsTooSmallSelectsLargestArea() {
        let available = CGRect(x: 0, y: 0, width: 300, height: 80)
        let division = CGRect(x: 200, y: 0, width: 20, height: 80)

        XCTAssertEqual(BulletinLayoutRegion.select(in: available, excluding: [division],
                                                   layoutDirection: .leftToRight,
                                                   preferredPoint: CGPoint(x: 260, y: 40)),
                       CGRect(x: 0, y: 0, width: 200, height: 80))
    }

    private func assertClearRegions(_ regions: [CGRect], within available: CGRect,
                                    excluding divisions: [CGRect],
                                    file: StaticString = #filePath, line: UInt = #line) {
        for region in regions {
            XCTAssertFalse(region.isEmpty, file: file, line: line)
            XCTAssertTrue(available.contains(region), file: file, line: line)
            for division in divisions {
                XCTAssertFalse(region.intersects(division), file: file, line: line)
            }
        }
    }
}
