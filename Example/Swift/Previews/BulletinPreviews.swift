/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

#if DEBUG
import SwiftUI
import UIKit
import CustomBulletins

@available(iOS 17, *)
#Preview("PetBoard") {
    UIStoryboard(name: "Main-Swift", bundle: nil).instantiateInitialViewController()!
}

@available(iOS 17, *)
#Preview("Name — Narrow", traits: .fixedLayout(width: 320, height: 568)) {
    BulletinPreviewController(item: BulletinDataSource.makeTextFieldPage())
}

@available(iOS 17, *)
#Preview("Birth Date — Narrow", traits: .fixedLayout(width: 320, height: 568)) {
    BulletinPreviewController(item: BulletinDataSource.makeDatePage(userName: "Alex"))
}

@available(iOS 17, *)
#Preview("Favorite Pets — Narrow", traits: .fixedLayout(width: 320, height: 568)) {
    BulletinPreviewController(item: BulletinDataSource.makeChoicePage())
}

@available(iOS 17, *)
#Preview("Pet Photos — Narrow", traits: .fixedLayout(width: 320, height: 568)) {
    BulletinPreviewController(item: PetValidationBLTNItem(dataSource: .cat, animalType: "cats") { _ in })
}

@available(iOS 17, *)
#Preview("Pet Care Guide — Short", traits: .fixedLayout(width: 568, height: 320)) {
    BulletinPreviewController(item: BulletinDataSource.makePetCarePage())
}
#endif
