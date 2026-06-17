/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BLTNBoard

/**
 * An item that displays a choice with two buttons.
 *
 * This item demonstrates how to create a page bulletin item with a custom interface, and changing the
 * next item based on user interaction.
 */

@objc public class PetSelectorBulletinPage: FeedbackPageBLTNItem {
    private var catButtonContainer: UIButton!
    private var dogButtonContainer: UIButton!
    private var selectionFeedbackGenerator = SelectionFeedbackGenerator()
    
    let completionHandler: (BLTNItem) -> Void

    @objc public init(completionHandler: @escaping (BLTNItem) -> Void) {
        self.completionHandler = completionHandler
        super.init(title: "Choose your Favorite")
    }
    
    // MARK: - BLTNItem

    /**
     * Called by the manager when the item is about to be removed from the bulletin.
     *
     * Use this function as an opportunity to do any clean up or remove tap gesture recognizers /
     * button targets from your views to avoid retain cycles.
     */

    public override func tearDown() {
        catButtonContainer?.removeTarget(self, action: nil, for: .touchUpInside)
        dogButtonContainer?.removeTarget(self, action: nil, for: .touchUpInside)
    }

    /**
     * Called by the manager to build the view hierachy of the bulletin.
     *
     * We need to return the view in the order we want them displayed. You should use a
     * `BulletinInterfaceFactory` to generate standard views, such as title labels and buttons.
     */
    
    public override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        
        let favoriteTabIndex = UserDefaults.standard.favoriteTabIndex

        // Pets Stack

        // We add choice cells to a group stack because they need less spacing
        let petsStack = interfaceBuilder.makeGroupStack(spacing: 16)

        // Cat Button

        let catButtonContainer = createChoiceCell(dataSource: .cat, isSelected: favoriteTabIndex == 0)
        catButtonContainer.addTarget(self, action: #selector(catButtonTapped), for: .touchUpInside)
        petsStack.addArrangedSubview(catButtonContainer)

        self.catButtonContainer = catButtonContainer

        // Dog Button

        let dogButtonContainer = createChoiceCell(dataSource: .dog, isSelected: favoriteTabIndex == 1)
        dogButtonContainer.addTarget(self, action: #selector(dogButtonTapped), for: .touchUpInside)
        petsStack.addArrangedSubview(dogButtonContainer)

        self.dogButtonContainer = dogButtonContainer

        return [petsStack]

    }

    // MARK: - Custom Views

    /**
     * Creates a custom choice cell.
     */

    func createChoiceCell(dataSource: CollectionDataSource, isSelected: Bool) -> UIButton {

        let choice = choiceContent(for: dataSource)

        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .center
        button.accessibilityLabel = choice.title

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 55)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        applyChoiceAppearance(to: button, dataSource: dataSource, isSelected: isSelected)

        if isSelected {
            next = PetValidationBLTNItem(dataSource: dataSource, animalType: choice.title.lowercased(), validationHandler: completionHandler)
        }

        return button

    }

    private func choiceContent(for dataSource: CollectionDataSource) -> (emoji: String, title: String) {
        switch dataSource {
        case .cat:
            return ("🐱", "Cats")
        case .dog:
            return ("🐶", "Dogs")
        }
    }

    private func applyChoiceAppearance(to button: UIButton, dataSource: CollectionDataSource, isSelected: Bool) {
        if isSelected {
            button.accessibilityTraits.insert(.selected)
        } else {
            button.accessibilityTraits.remove(.selected)
        }

        button.isSelected = false

        let choice = choiceContent(for: dataSource)
        if #available(iOS 26, *) {
            applyClearGlassChoiceAppearance(to: button, choice: choice, isSelected: isSelected)
        } else {
            applyBorderedChoiceAppearance(to: button, choice: choice, isSelected: isSelected)
        }
    }

    @available(iOS 26, *)
    private func applyClearGlassChoiceAppearance(to button: UIButton, choice: (emoji: String, title: String), isSelected: Bool) {
        var configuration = UIButton.Configuration.clearGlass()
        configuration.title = choice.emoji + " " + choice.title
        configuration.buttonSize = .large
        configuration.cornerStyle = .capsule
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        configuration.baseForegroundColor = isSelected ? appearance.actionButtonColor : .label
        configuration.automaticallyUpdateForSelection = false

        var background = configuration.background
        background.strokeColor = isSelected ? appearance.actionButtonColor : .tertiaryLabel
        background.strokeWidth = isSelected ? 2 : 1
        configuration.background = background

        let font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
            var updated = container
            updated.font = font
            return updated
        }

        UIView.transition(with: button, duration: 0.18, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            button.backgroundColor = .clear
            button.layer.borderWidth = 0
            button.configuration = configuration
        }
    }

    private func applyBorderedChoiceAppearance(to button: UIButton, choice: (emoji: String, title: String), isSelected: Bool) {
        let buttonColor = isSelected ? appearance.actionButtonColor : UIColor.tertiaryLabel

        button.configuration = nil
        button.setTitle(choice.emoji + " " + choice.title, for: .normal)
        button.setTitleColor(isSelected ? appearance.actionButtonColor : .secondaryLabel, for: .normal)
        button.setTitleColor(isSelected ? appearance.actionButtonColor : .secondaryLabel, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 27.5
        button.layer.cornerCurve = .continuous
        button.layer.borderColor = buttonColor.cgColor
        button.layer.borderWidth = isSelected ? 2 : 1
    }

    // MARK: - Touch Events

    /// Called when the cat button is tapped.
    @objc func catButtonTapped() {
        selectChoice(.cat)
    }

    /// Called when the dog button is tapped.
    @objc func dogButtonTapped() {
        selectChoice(.dog)
    }

    private func selectChoice(_ dataSource: CollectionDataSource) {

        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        let selectedIndex: Int
        switch dataSource {
        case .cat:
            selectedIndex = 0
        case .dog:
            selectedIndex = 1
        }

        applyChoiceAppearance(to: catButtonContainer, dataSource: .cat, isSelected: selectedIndex == 0)
        applyChoiceAppearance(to: dogButtonContainer, dataSource: .dog, isSelected: selectedIndex == 1)

        let choice = choiceContent(for: dataSource)

        NotificationCenter.default.post(name: .FavoriteTabIndexDidChange,
                                        object: self,
                                        userInfo: ["Index": selectedIndex])

        next = PetValidationBLTNItem(dataSource: dataSource, animalType: choice.title.lowercased(), validationHandler: completionHandler)
    }

    override public func actionButtonTapped(sender: UIButton) {
        // Play haptic feedback
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // Ask the manager to present the next item.
        manager?.displayNextItem()
    }
}
