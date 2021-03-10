//
//  AlertViewModel.swift
//  MyRooms
//
//  Created by Germán Azcona on 10/03/2021.
//

import Foundation
import UIKit

/// A simple view model to separate the alert data from the view controller.
struct AlertViewModel {

    var title: String?
    var message: String?
    var actions: [UIAlertAction]
}

enum AlertViewKeys: String, Localizable {
    case errorTitle =       "generic__error_alert___title"
    case successTitle =     "generic__success_alert___title"
    case ok =               "generic__alert___ok"
}

extension AlertViewModel {

    /// Quick initializer for showing error alerts with default title and dismiss button.
    init(errorMessage: String?) {
        self.init(
            title: AlertViewKeys.errorTitle.localized,
            message: errorMessage,
            actions: [
                UIAlertAction(title: AlertViewKeys.ok.localized,
                              style: .default,
                              handler: nil)
            ]
        )
    }

    /// Quick initializer for showing success alerts with default title and dismiss button.
    init(successMessage: String?) {
        self.init(
            title: AlertViewKeys.successTitle.localized,
            message: successMessage,
            actions: [
                UIAlertAction(title: AlertViewKeys.ok.localized,
                              style: .default,
                              handler: nil)
            ]
        )
    }
}

extension UIViewController {

    /// Easily show alert view models.
    func presentAlert(with alertViewModel: AlertViewModel) {

        // TODO: Change UIAlertController for whatever component that supports AlertViewModel.
        let controller = UIAlertController(
            title: alertViewModel.title,
            message: alertViewModel.message,
            preferredStyle: .alert
        )
        alertViewModel.actions.forEach { controller.addAction($0) }
        present(controller, animated: true, completion: nil)
    }
}
