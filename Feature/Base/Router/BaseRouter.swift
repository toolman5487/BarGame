//
//  BaseRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SafariServices
import UIKit
internal import os

// MARK: - RouterPresentation

@MainActor
enum RouterPresentation {
    case push
    case present
    case fullScreen
    case formSheet
    case pageSheet(RouterPageSheetConfiguration)
    case popover(RouterPopoverConfiguration)
}

// MARK: - RouterPageSheetConfiguration

@MainActor
struct RouterPageSheetConfiguration {
    let detents: [UISheetPresentationController.Detent]
    let prefersGrabber: Bool
    let embedInNavigationController: Bool

    init(
        detents: [UISheetPresentationController.Detent] = [.large()],
        prefersGrabber: Bool = true,
        embedInNavigationController: Bool = true
    ) {
        self.detents = detents
        self.prefersGrabber = prefersGrabber
        self.embedInNavigationController = embedInNavigationController
    }

    static let medium = RouterPageSheetConfiguration(detents: [.medium()])
    static let large = RouterPageSheetConfiguration(detents: [.large()])
    static let mediumAndLarge = RouterPageSheetConfiguration(detents: [.medium(), .large()])
}

// MARK: - RouterPopoverConfiguration

@MainActor
struct RouterPopoverConfiguration {
    let sourceView: UIView
    let sourceRect: CGRect
    let permittedArrowDirections: UIPopoverArrowDirection

    init(
        sourceView: UIView,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection = .any
    ) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect ?? sourceView.bounds
        self.permittedArrowDirections = permittedArrowDirections
    }
}

// MARK: - BaseRouter

@MainActor
class BaseRouter {

    // MARK: - Properties

    private(set) weak var sourceViewController: UIViewController?

    var mainTabBarController: MainTabBarController? {
        sourceViewController?.tabBarController as? MainTabBarController
    }

    // MARK: - Initialization

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }

    // MARK: - Presentation

    func show(_ viewController: UIViewController, using presentation: RouterPresentation) {
        guard let sourceViewController else {
            AppLogger.navigation.warning(
                "Router presentation failed because sourceViewController was released."
            )
            return
        }

        switch presentation {
        case .push:
            guard let navigationController = sourceViewController.navigationController else {
                AppLogger.navigation.warning(
                    "Router push failed because sourceViewController is not embedded in a navigation controller."
                )
                return
            }

            navigationController.pushViewController(viewController, animated: true)

        case .present:
            present(viewController, from: sourceViewController)

        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
            present(viewController, from: sourceViewController)

        case .formSheet:
            viewController.modalPresentationStyle = .formSheet
            present(viewController, from: sourceViewController)

        case .pageSheet(let configuration):
            let presentedViewController = makePageSheetViewController(
                from: viewController,
                configuration: configuration
            )
            present(presentedViewController, from: sourceViewController)

        case .popover(let configuration):
            viewController.modalPresentationStyle = .popover

            if let popover = viewController.popoverPresentationController {
                popover.sourceView = configuration.sourceView
                popover.sourceRect = configuration.sourceRect
                popover.permittedArrowDirections = configuration.permittedArrowDirections
            }

            present(viewController, from: sourceViewController)
        }
    }

    func openSafari(_ url: URL) {
        guard let sourceViewController else {
            AppLogger.navigation.warning(
                "Router Safari presentation failed because sourceViewController was released."
            )
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, from: sourceViewController)
    }

    // MARK: - Alert

    func showAlert(
        title: String,
        message: String,
        actionTitle: String = "確定"
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: actionTitle, style: .default))
        show(alert, using: .present)
    }

    func showConfirmationAlert(
        title: String,
        message: String,
        actionTitle: String,
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(
            UIAlertAction(title: actionTitle, style: .destructive) { _ in
                onConfirm()
            }
        )
        show(alert, using: .present)
    }

    // MARK: - Private Methods

    private func makePageSheetViewController(
        from viewController: UIViewController,
        configuration: RouterPageSheetConfiguration
    ) -> UIViewController {
        let presentedViewController: UIViewController

        if configuration.embedInNavigationController {
            presentedViewController = UINavigationController(rootViewController: viewController)
        } else {
            presentedViewController = viewController
        }

        presentedViewController.modalPresentationStyle = .pageSheet

        if let sheet = presentedViewController.sheetPresentationController {
            sheet.detents = configuration.detents
            sheet.prefersGrabberVisible = configuration.prefersGrabber
        }

        return presentedViewController
    }

    private func present(
        _ viewController: UIViewController,
        from sourceViewController: UIViewController
    ) {
        let presenter = topPresenter(from: sourceViewController)
        presenter.present(viewController, animated: true)
    }

    private func topPresenter(from sourceViewController: UIViewController) -> UIViewController {
        var presenter = sourceViewController

        while let presentedViewController = presenter.presentedViewController,
              !presentedViewController.isBeingDismissed {
            presenter = presentedViewController
        }

        return presenter
    }
}
