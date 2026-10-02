import UIKit

/**
 * The presentation used for a bulletin.
 */
public enum BLTNPresentationStyle: Int, Sendable {

    /// The custom BulletinBoard card, background, and gestures.
    case custom

    /**
     * A system sheet on iOS 26 and later. Earlier releases use the custom card.
     *
     * UIKit controls the sheet background, corners, placement, and keyboard behavior.
     * Custom card background, corner radius, edge spacing, and keyboard opt-out settings
     * do not apply. On iOS 27 and later the sheet uses trailing placement.
     */
    case nativeSheet

}
