#if DEBUG
import UIKit

/// Runs the public manager API in a real presentation hierarchy inside the canvas.
@available(iOS 17, *)
final class FrameworkPreviewController: UIViewController {
    private let scenario: FrameworkPreviewScenario
    private let presentationStyle: BLTNPresentationStyle
    private let previewContentSize: UIContentSizeCategory?
    private let previewRightToLeft: Bool
    private var manager: BLTNItemManager?
    private var hasPresented = false
    private var loadingTask: Task<Void, Never>?
    private let statusLabel = UILabel()

    init(scenario: FrameworkPreviewScenario, presentationStyle: BLTNPresentationStyle = .custom,
         interfaceStyle: UIUserInterfaceStyle = .unspecified,
         contentSize: UIContentSizeCategory? = nil, rightToLeft: Bool = false) {
        self.scenario = scenario
        self.presentationStyle = presentationStyle
        self.previewContentSize = contentSize
        self.previewRightToLeft = rightToLeft
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = interfaceStyle
        if let contentSize {
            traitOverrides.preferredContentSizeCategory = contentSize
        }
        if rightToLeft {
            traitOverrides.layoutDirection = .rightToLeft
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(scenario:) for framework previews.")
    }

    nonisolated deinit {
        loadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let background = UIImageView(image: Self.makeBackground())
        background.contentMode = .scaleToFill
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Show Bulletin"
        button.configuration = configuration
        button.addAction(UIAction { [weak self] _ in self?.showBulletin() }, for: .touchUpInside)
        statusLabel.text = "Close the bulletin to restart the preview."
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .label
        statusLabel.textAlignment = .center
        let controls = UIStackView(arrangedSubviews: [button, statusLabel])
        controls.axis = .vertical
        controls.spacing = 12
        controls.backgroundColor = .systemBackground
        controls.isLayoutMarginsRelativeArrangement = true
        controls.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        NSLayoutConstraint.activate([
            controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPresented else { return }
        hasPresented = true
        showBulletin()
    }

    private func showBulletin() {
        guard manager?.isShowingBulletin != true else { return }
        loadingTask?.cancel()
        let item = scenario.makeItem { [weak self] form in self?.submit(form) }
        recordEvents(for: item)
        let manager = BLTNItemManager(rootItem: item)
        manager.presentationStyle = presentationStyle
        self.manager = manager
        manager.showBulletin(above: self, animated: false)
        // UIKit can present from an ancestor outside the canvas host's trait scope.
        if let controller = manager.presentationController {
            controller.overrideUserInterfaceStyle = overrideUserInterfaceStyle
            if let previewContentSize {
                controller.traitOverrides.preferredContentSizeCategory = previewContentSize
            }
            if previewRightToLeft {
                controller.traitOverrides.layoutDirection = .rightToLeft
            }
        }
    }

    private func submit(_ form: FrameworkPreviewFormItem) {
        guard let manager = form.manager else { return }
        loadingTask?.cancel()
        manager.displayActivityIndicator()
        loadingTask = Task { @MainActor [weak self, weak manager] in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            guard let self, let manager, manager.isShowingBulletin else { return }
            manager.hideActivityIndicator()
            let item = BLTNPageItem(title: "Submission complete")
            item.descriptionText = "Saved name: \(form.name). Choose Back to check field preservation, or Finish to close the bulletin."
            item.actionButtonTitle = "Finish"
            item.actionHandler = { $0.manager?.dismissBulletin() }
            item.alternativeButtonTitle = "Back"
            item.alternativeHandler = { $0.manager?.popItem() }
            self.recordEvents(for: item)
            manager.push(item: item)
            self.loadingTask = nil
        }
    }

    private func recordEvents(for item: BLTNPageItem) {
        let title = item.title
        item.presentationHandler = { [weak self] _ in self?.statusLabel.text = "Presented: \(title)" }
        item.dismissalHandler = { [weak self] _ in self?.statusLabel.text = "Dismissed: \(title). Show Bulletin starts a new flow." }
    }

    private static func makeBackground() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 240, height: 240)).image { context in
            for (index, color) in [UIColor.systemTeal, .systemOrange, .systemPink, .systemIndigo].enumerated() {
                color.setFill()
                context.fill(CGRect(x: 0, y: index * 60, width: 240, height: 60))
            }
        }
    }
}
#endif
