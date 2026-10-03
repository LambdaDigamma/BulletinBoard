#if DEBUG
import UIKit

@available(iOS 17, *)
enum FrameworkPreviewScenario {
    case actions
    case form
    case longContent

    func makeItem(onSubmit: @escaping (FrameworkPreviewFormItem) -> Void) -> BLTNPageItem {
        switch self {
        case .actions:
            let item = BLTNPageItem(title: "Bulletin actions")
            item.descriptionText = "Open an alert above this bulletin, or close it and use Show Bulletin to start again."
            item.actionButtonTitle = "Open Alert"
            item.actionHandler = { item in
                let alert = UIAlertController(title: "Preview alert", message: "Close this alert to return to the bulletin.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Return", style: .default))
                item.manager?.present(alert, animated: true)
            }
            item.alternativeButtonTitle = "Dismiss"
            item.alternativeHandler = { $0.manager?.dismissBulletin() }
            return item
        case .form:
            let item = FrameworkPreviewFormItem(title: "Your name")
            item.descriptionText = "Edit the field, then submit. Loading blocks dismissal for one second. Back returns to the saved field."
            item.actionButtonTitle = "Submit"
            item.actionHandler = { item in
                guard let form = item as? FrameworkPreviewFormItem else { return }
                form.saveName()
                onSubmit(form)
            }
            item.alternativeButtonTitle = "Dismiss"
            item.alternativeHandler = { $0.manager?.dismissBulletin() }
            return item
        case .longContent:
            let item = BLTNPageItem(title: "Scrollable bulletin")
            item.descriptionText = (1...12).map {
                "Section \($0): Resize the preview or use a larger text size. All text and the final action must remain reachable."
            }.joined(separator: "\n\n")
            item.actionButtonTitle = "Done"
            item.actionHandler = { $0.manager?.dismissBulletin() }
            return item
        }
    }
}
#endif
