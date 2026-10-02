/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/// Selects one area that can contain the whole bulletin without crossing a division.
struct BulletinLayoutRegion {

    /// All input frames must use the same local coordinate system.
    static func regions(in rect: CGRect, excluding divisions: [CGRect]) -> [CGRect] {
        guard isUsable(rect) else { return [] }

        return divisions.reduce([rect]) { candidates, division in
            guard isUsable(division) else { return candidates }

            return candidates.flatMap { candidate in
                let intersection = candidate.intersection(division)
                guard isUsable(intersection) else { return [candidate] }

                let remaining: [CGRect]
                if isVertical(division) {
                    remaining = [
                        CGRect(x: candidate.minX, y: candidate.minY,
                               width: intersection.minX - candidate.minX, height: candidate.height),
                        CGRect(x: intersection.maxX, y: candidate.minY,
                               width: candidate.maxX - intersection.maxX, height: candidate.height),
                    ]
                } else {
                    remaining = [
                        CGRect(x: candidate.minX, y: candidate.minY,
                               width: candidate.width, height: intersection.minY - candidate.minY),
                        CGRect(x: candidate.minX, y: intersection.maxY,
                               width: candidate.width, height: candidate.maxY - intersection.maxY),
                    ]
                }
                return remaining.filter(isUsable)
            }
        }
    }

    static func select(in rect: CGRect, excluding divisions: [CGRect],
                       layoutDirection: UIUserInterfaceLayoutDirection,
                       preferredPoint: CGPoint? = nil) -> CGRect {
        let candidates = regions(in: rect, excluding: divisions)
        guard !candidates.isEmpty else { return .zero }

        // A keyboard can leave a narrow strip below a horizontal division.
        let usableCandidates = candidates.filter { $0.width >= 120 && $0.height >= 96 }
        guard !usableCandidates.isEmpty else {
            return candidates.max { area(of: $0) < area(of: $1) } ?? .zero
        }

        if let preferredPoint,
           let currentRegion = usableCandidates.first(where: { $0.contains(preferredPoint) }) {
            return currentRegion
        }

        let activeDivisions = divisions.filter {
            isUsable($0) && isUsable(rect.intersection($0))
        }
        let hasVerticalDivision = activeDivisions.contains(where: isVertical)
        let hasHorizontalDivision = activeDivisions.contains { !isVertical($0) }

        return usableCandidates.max { first, second in
            if hasHorizontalDivision && first.midY != second.midY {
                return first.midY < second.midY
            }
            if hasVerticalDivision && first.midX != second.midX {
                return layoutDirection == .rightToLeft
                    ? first.midX > second.midX
                    : first.midX < second.midX
            }
            return area(of: first) < area(of: second)
        } ?? .zero
    }

    private static func isUsable(_ rect: CGRect) -> Bool {
        return rect.width > 0 && rect.height > 0
            && rect.minX.isFinite && rect.minY.isFinite
            && rect.maxX.isFinite && rect.maxY.isFinite
    }

    private static func isVertical(_ division: CGRect) -> Bool {
        return division.height >= division.width
    }

    private static func area(of rect: CGRect) -> CGFloat {
        return rect.width * rect.height
    }
}
