import UIKit

/**
 * The presentation used for a bulletin.
 */
public enum BLTNPresentationStyle: Int, Sendable {

    /// Retained for source compatibility. Uses the native sheet.
    @available(*, deprecated, message: "The custom presenter was removed. Use the default native sheet.")
    case custom

    /// A native sheet on every supported iOS release. UIKit controls its appearance and keyboard behavior.
    case nativeSheet

}
