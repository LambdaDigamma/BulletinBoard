#if DEBUG
import UIKit

@available(iOS 17, *)
final class FrameworkPreviewFormItem: BLTNPageItem, UITextFieldDelegate {
    nonisolated deinit {}

    private(set) var name = "Alex"
    private weak var textField: UITextField?

    override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Name"
        field.accessibilityLabel = "Name"
        field.text = name
        field.returnKeyType = .done
        field.autocapitalizationType = .words
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.delegate = self
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        textField = field
        return [field]
    }

    func saveName() {
        name = textField?.text ?? name
        textField?.resignFirstResponder()
    }

    override func tearDown() {
        saveName()
        textField?.delegate = nil
        textField = nil
        super.tearDown()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveName()
        return true
    }
}
#endif
