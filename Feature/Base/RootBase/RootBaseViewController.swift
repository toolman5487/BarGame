//
//  RootBaseViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import UIKit

@MainActor
class RootBaseViewController: UIViewController {

    // MARK: - Keyboard Configuration

    var isKeyboardHandlingEnabled: Bool { true }

    var isResignOnTouchOutsideEnabled: Bool { true }

    var keyboardDistanceFromTextField: CGFloat { 16 }

    // MARK: - State

    private var keyboardFrame: CGRect = .zero
    private var adjustedScrollView: UIScrollView?
    private var originalScrollContentInset: UIEdgeInsets = .zero
    private var originalScrollIndicatorInsets: UIEdgeInsets = .zero
    private var originalAdditionalSafeAreaInsets: UIEdgeInsets = .zero
    private var isKeyboardVisible = false
    private var isKeyboardObserversRegistered = false

    private lazy var resignKeyboardTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleResignKeyboardTap)
        )
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureKeyboardHandling()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isKeyboardHandlingEnabled else { return }
        addKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        removeKeyboardObservers()
        restoreKeyboardAvoidance(animated: false)
    }
}

// MARK: - Keyboard Setup

private extension RootBaseViewController {

    func configureKeyboardHandling() {
        guard isKeyboardHandlingEnabled else { return }
        originalAdditionalSafeAreaInsets = additionalSafeAreaInsets

        guard isResignOnTouchOutsideEnabled else { return }
        view.addGestureRecognizer(resignKeyboardTapGesture)
    }
}

// MARK: - Keyboard Observers

private extension RootBaseViewController {

    func addKeyboardObservers() {
        guard !isKeyboardObserversRegistered else { return }

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrameNotification(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleKeyboardWillHideNotification(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        isKeyboardObserversRegistered = true
    }

    func removeKeyboardObservers() {
        guard isKeyboardObserversRegistered else { return }

        let center = NotificationCenter.default
        center.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        center.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        isKeyboardObserversRegistered = false
    }

    @objc
    func handleKeyboardWillChangeFrameNotification(_ notification: Notification) {
        handleKeyboardFrameChange(notification)
    }

    @objc
    func handleKeyboardWillHideNotification(_ notification: Notification) {
        handleKeyboardWillHide(notification)
    }
}

// MARK: - Keyboard Avoidance

private extension RootBaseViewController {

    func handleKeyboardFrameChange(_ notification: Notification) {
        guard isKeyboardHandlingEnabled,
              isViewLoaded,
              view.window != nil,
              let userInfo = notification.userInfo,
              let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardFrameInView = view.convert(endFrame, from: nil)
        let overlap = view.bounds.intersection(keyboardFrameInView)
        let keyboardHeight = overlap.isNull ? 0 : overlap.height

        keyboardFrame = keyboardFrameInView
        isKeyboardVisible = keyboardHeight > 0

        guard isKeyboardVisible else {
            restoreKeyboardAvoidance(animated: true, userInfo: userInfo)
            return
        }

        applyKeyboardAvoidance(
            keyboardHeight: keyboardHeight,
            userInfo: userInfo
        )
    }

    func handleKeyboardWillHide(_ notification: Notification) {
        guard isKeyboardHandlingEnabled else { return }
        isKeyboardVisible = false
        keyboardFrame = .zero
        restoreKeyboardAvoidance(
            animated: true,
            userInfo: notification.userInfo
        )
    }

    func applyKeyboardAvoidance(
        keyboardHeight: CGFloat,
        userInfo: [AnyHashable: Any]?
    ) {
        let bottomInset = max(
            0,
            keyboardHeight
                - view.safeAreaInsets.bottom
                + keyboardDistanceFromTextField
        )

        animateKeyboardTransition(userInfo: userInfo) {
            if let scrollView = self.nearestScrollView(for: self.currentFirstResponder()) {
                self.adjust(scrollView: scrollView, bottomInset: bottomInset)
            } else {
                var insets = self.originalAdditionalSafeAreaInsets
                insets.bottom = max(
                    self.originalAdditionalSafeAreaInsets.bottom,
                    bottomInset
                )
                self.additionalSafeAreaInsets = insets
            }
            self.view.layoutIfNeeded()
            self.scrollFirstResponderIntoVisibleAreaIfNeeded()
        }
    }

    func restoreKeyboardAvoidance(
        animated: Bool,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        let updates = {
            if let scrollView = self.adjustedScrollView {
                scrollView.contentInset = self.originalScrollContentInset
                scrollView.verticalScrollIndicatorInsets = self.originalScrollIndicatorInsets
            }
            self.additionalSafeAreaInsets = self.originalAdditionalSafeAreaInsets
            self.adjustedScrollView = nil
            self.view.layoutIfNeeded()
        }

        if animated {
            animateKeyboardTransition(userInfo: userInfo, animations: updates)
        } else {
            updates()
        }
    }

    func adjust(scrollView: UIScrollView, bottomInset: CGFloat) {
        if adjustedScrollView !== scrollView {
            if let previousScrollView = adjustedScrollView {
                previousScrollView.contentInset = originalScrollContentInset
                previousScrollView.verticalScrollIndicatorInsets = originalScrollIndicatorInsets
            }
            adjustedScrollView = scrollView
            originalScrollContentInset = scrollView.contentInset
            originalScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        }

        var contentInset = originalScrollContentInset
        contentInset.bottom = max(originalScrollContentInset.bottom, bottomInset)
        scrollView.contentInset = contentInset
        scrollView.verticalScrollIndicatorInsets = contentInset
    }

    func scrollFirstResponderIntoVisibleAreaIfNeeded() {
        guard let firstResponder = currentFirstResponder() as? UIView,
              let scrollView = nearestScrollView(for: firstResponder)
        else { return }

        let padding = keyboardDistanceFromTextField
        let responderFrameInView = firstResponder.convert(firstResponder.bounds, to: view)
        let keyboardHeight = max(0, view.bounds.intersection(keyboardFrame).height)
        let visibleMaxY = view.bounds.maxY - keyboardHeight - padding

        guard responderFrameInView.maxY > visibleMaxY else { return }

        let offsetY = responderFrameInView.maxY - visibleMaxY
        var contentOffset = scrollView.contentOffset
        contentOffset.y += offsetY
        let maxOffsetY = max(
            0,
            scrollView.contentSize.height
                + scrollView.adjustedContentInset.bottom
                - scrollView.bounds.height
        )
        contentOffset.y = min(
            max(contentOffset.y, -scrollView.adjustedContentInset.top),
            maxOffsetY
        )
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    func animateKeyboardTransition(
        userInfo: [AnyHashable: Any]?,
        animations: @escaping () -> Void
    ) {
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?
            .doubleValue ?? 0.25
        let curveValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?
            .uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
            .union(.beginFromCurrentState)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: animations
        )
    }
}

// MARK: - First Responder Helpers

private extension RootBaseViewController {

    func currentFirstResponder() -> UIResponder? {
        findFirstResponder(in: view)
    }

    func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder {
            return view
        }

        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        return nil
    }

    func nearestScrollView(for responder: UIResponder?) -> UIScrollView? {
        var current = responder as? UIView
        while let view = current {
            if let scrollView = view as? UIScrollView,
               !(scrollView is UITextView) {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}

// MARK: - Resign On Touch Outside

private extension RootBaseViewController {

    @objc
    func handleResignKeyboardTap() {
        view.endEditing(true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension RootBaseViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard isKeyboardHandlingEnabled,
              isResignOnTouchOutsideEnabled,
              gestureRecognizer === resignKeyboardTapGesture
        else { return false }

        var view = touch.view
        while let current = view {
            if current is UIControl || current is UITextView {
                return false
            }
            view = current.superview
        }
        return true
    }
}
