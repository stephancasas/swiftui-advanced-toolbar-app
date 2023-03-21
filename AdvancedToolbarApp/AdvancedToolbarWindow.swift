//
//  AdvancedToolbarWindow.swift
//
//  Created by Stephan Casas on 3/17/23.
//

import SwiftUI;
import AppKit;

class AdvancedToolbarWindow<MainContent: View, TitleToolbarContent: View>: NSWindow, NSToolbarDelegate {
    private let titleToolbarContent: () -> TitleToolbarContent;
    
    /// Create a new window styled with a unified titlebar and inset traffic signals.
    /// - Parameters:
    ///   - withTitle: The window title.
    ///   - contentRect: The window's main content size.
    ///   - contentView: The window's main content view.
    convenience init(
        withTitle: String,
        contentRect: NSRect = CGRect(x:0, y: 0, width: 620, height: 400),
        _ contentView: () -> MainContent
    ) where TitleToolbarContent == EmptyView {
        self.init( withTitle: withTitle,
                   contentRect: contentRect,
                   withTitleToolbar: { EmptyView() },
                   contentView);
    }
    
    /// Create a new window styled with a unified titlebar and inset traffic signals,
    /// including title toolbar anchored before the window title in the titlebar.
    /// - Parameters:
    ///   - withTitle: The window title.
    ///   - contentRect: The window's main content size.
    ///   - withTitleToolbar: The window's title toolbar content view.
    ///   - contentView: The window's main content view.
    init(
        withTitle: String,
        contentRect: NSRect = CGRect(x:0, y: 0, width: 620, height: 400),
        withTitleToolbar: @escaping () -> TitleToolbarContent,
        _ contentView: () -> MainContent
    ) {
        self.titleToolbarContent = withTitleToolbar;
        
        super.init(
            contentRect: contentRect,
            styleMask: [.closable, .miniaturizable, .resizable,
                        .titled, .unifiedTitleAndToolbar, .fullSizeContentView],
            backing: .buffered,
            defer: false);
        self.contentView = NSHostingView(rootView: contentView().ignoresSafeArea())
        
        /// Init empty `NSToolbar` to fill with SwiftUI later...
        let toolbar = NSToolbar(identifier: "\(withTitle)");
        toolbar.displayMode = .iconOnly;
        
        /// Mount and style empty `NSToolbar` to offset traffic signal insets
        self.toolbar = toolbar;
        self.toolbar!.isVisible = true;
        self.toolbar!.displayMode = .iconOnly
        self.toolbarStyle = .automatic;
        
        /// Apply title and style titlebar
        self.title = withTitle;
        self.titleVisibility = .visible;
        self.titlebarAppearsTransparent = true;
        
        //MARK: Install AccessoryView
        
        /// This `NSWindow` style will draw four components in the titlebar:
        ///
        ///  * `NSTitlebarView`
        ///  * `NSTitlebarContainerBlockingView`
        ///  * `NSToolbarView`
        ///  * `NSToolbarTitleView`
        ///
        /// We must defer installing `NSTitlebarAccessoryViewController` until
        /// these components mount during the next UI draw cycle.
        ///
        DispatchQueue.main.async(execute: self.installTitleToolbar);
    }
    
    internal func installTitleToolbar() {
        /// Skip for `EmptyView()` to avoid blank space with offsets
        let titleToolbar = titleToolbarContent();
        if type(of: titleToolbar) == EmptyView.self { return }
        
        let accessoryView = NSHostingView(rootView: titleToolbar);
        
        /// create the accessory to the *left* of the window's title
        let accessory = NSTitlebarAccessoryViewController();
        accessory.view = accessoryView;
        accessory.layoutAttribute = .left
        
        self.addTitlebarAccessoryViewController(accessory);
        
        /// `NSClipView`
        guard let accessoryClipView = accessoryView.superview else { return }
        /// `NSTitlebarView`
        guard let  titlebarView = accessoryClipView.superview else { return }
        /// `NSTitlebarContainerBlockingView`
        guard let titlebarBlock = titlebarView.superview?.subviews.last else { return }
        
        /// `NSToolbarView`
        ///
        /// The toolbar may be at different positions depending on the window style.
        /// We can't use a type comparison to locate it, because `NSToolbarView` is a
        /// private class. Instead, we can key on each subview's accessibility role
        /// until we find *"toolbar"*.
        guard let toolbarView = titlebarView.subviews.first(where: { view in
            guard let role = view.accessibilityRoleDescription() else { return false }
            return role == "toolbar"; // FIXME: This string may need localization.
        }) else { return }
        
        /// `NSToolbarTitleView`
        ///
        /// We'll need this view so that we can re-assign its leading constraint to
        /// come *after* our newly-installed button.
        guard let toolbarTitleView = toolbarView.subviews.first else { return }
        
        /// Disable the auto-resizing mask constraints for **everything**.
        accessoryView.translatesAutoresizingMaskIntoConstraints     = false;
        accessoryClipView.translatesAutoresizingMaskIntoConstraints = false;
        toolbarTitleView.translatesAutoresizingMaskIntoConstraints  = false;
        
        /// Our button inside of `NSTitlebarAccessoryViewController` should appear
        /// *before* the window title, but *after* the sidebar with slight padding
        /// on its leading edge.
        ///
        /// It should also occupy the full height of the unified titlebar/toolbar
        /// area so that we can handle alignment in SwiftUI.
        ///
        /// For both of these, we'll constrain the `NSClipView` of the accessory
        /// on `NSTitlebarContainerBlockingView`. We'll leave the trailing edge
        /// unconstrained so that it can grow with SwiftUI-provided content.
        NSLayoutConstraint.activate([
            accessoryClipView.leadingAnchor.constraint(
                equalTo: titlebarBlock.leadingAnchor,
                constant: 7),
            accessoryClipView.topAnchor.constraint(equalTo: titlebarBlock.topAnchor),
            accessoryClipView.bottomAnchor.constraint(equalTo: titlebarBlock.bottomAnchor),
        ]);
        
        /// Now, we need to constrain our `NSHostingView` to the bounds of the
        /// `NSClipView` in which it is contained. This will allow it to occupy
        /// the exact same space, and will let us handle alignment in SwiftUI.
        NSLayoutConstraint.activate([
            accessoryView.leadingAnchor.constraint(equalTo: accessoryClipView.leadingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: accessoryClipView.trailingAnchor),
            accessoryView.topAnchor.constraint(equalTo: accessoryClipView.topAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: accessoryClipView.bottomAnchor)
        ]);
        
        /// Finally, we must offset the window title to the trailing edge of
        /// our accessory -- such that it does not overlap.
        ///
        /// The `NSToolbarTitleView` already includes a leading edge inset, so
        /// we do not need to apply another constant here.
        NSLayoutConstraint.activate([
            toolbarTitleView.leadingAnchor.constraint(equalTo: accessoryView.trailingAnchor)
        ]);
    }
    
    override var canBecomeKey: Bool {
        return true;
    }
    
    override var canBecomeMain: Bool {
        return true;
    }
}
