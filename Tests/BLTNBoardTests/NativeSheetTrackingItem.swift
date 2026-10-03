import UIKit
@testable import BLTNBoard

@MainActor
final class NativeSheetTrackingItem: BLTNItem {
    private let contentHeight: CGFloat

    private(set) var makeViewsCount = 0
    private(set) var setUpCount = 0
    private(set) var tearDownCount = 0
    private(set) var willDisplayCount = 0
    private(set) var displayCount = 0
    private(set) var dismissCount = 0
    private(set) var textField: UITextField?
    var willDisplayHandler: (() -> Void)?

    init(contentHeight: CGFloat = 140) {
        self.contentHeight = contentHeight
        super.init()
    }

    nonisolated deinit {}

    override func makeArrangedSubviews() -> [UIView] {
        makeViewsCount += 1
        let content = UILabel()
        content.text = "Test bulletin"
        content.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        let field = UITextField()
        field.placeholder = "Keep this field"
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        textField = field
        return [content, field]
    }

    override func setUp() { setUpCount += 1 }
    override func tearDown() { tearDownCount += 1 }
    override func willDisplay() {
        willDisplayCount += 1
        willDisplayHandler?()
    }

    override func onDisplay() {
        displayCount += 1
        super.onDisplay()
    }

    override func onDismiss() {
        dismissCount += 1
        super.onDismiss()
    }
}
