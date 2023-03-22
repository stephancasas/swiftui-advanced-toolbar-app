//
//  AdvancedToolbarWindow.swift
//
//  Created by Stephan Casas on 3/17/23.
//

import SwiftUI;
import AppKit;

class AdvancedToolbarWindow<MainContent: View, ToolbarContent: View, TitleToolbarContent: View>: NSWindow, NSToolbarDelegate {
    private let toolbarContent: () -> ToolbarContent;
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
    ) where TitleToolbarContent == EmptyView, ToolbarContent == EmptyView {
        self.init( withTitle: withTitle,
                   contentRect: contentRect,
                   withToolbar: { EmptyView() },
                   withTitleToolbar: { EmptyView() },
                   contentView);
    }
    
    /// Create a new window styled with a unified titlebar and inset traffic
    /// signals, — including a main toolbar anchored after the window title
    /// in the titlebar.
    /// - Parameters:
    ///   - withTitle: The window title.
    ///   - contentRect: The window's main content size.
    ///   - withToolbar: The window's toolbar content view.
    ///   - contentView: The window's main content view.
    convenience init(
        withTitle: String,
        contentRect: NSRect = CGRect(x:0, y: 0, width: 620, height: 400),
        withToolbar: @escaping () -> ToolbarContent,
        _ contentView: () -> MainContent
    ) where TitleToolbarContent == EmptyView {
        self.init(
            withTitle: withTitle,
            withToolbar: withToolbar,
            withTitleToolbar: { EmptyView() },
            contentView);
    }
    
    /// Create a new window styled with a unified titlebar and inset traffic
    /// signals, — including a title toolbar anchored before the window title
    /// in the titlebar.
    /// - Parameters:
    ///   - withTitle: The window title.
    ///   - contentRect: The window's main content size.
    ///   - withTitleToolbar: The window's toolbar content view.
    ///   - contentView: The window's main content view.
    convenience init(
        withTitle: String,
        contentRect: NSRect = CGRect(x:0, y: 0, width: 620, height: 400),
        withTitleToolbar: @escaping () -> TitleToolbarContent,
        _ contentView: () -> MainContent
    ) where ToolbarContent == EmptyView {
        self.init(
            withTitle: withTitle,
            withToolbar: { EmptyView() },
            withTitleToolbar: withTitleToolbar,
            contentView);
    }
    
    /// Create a new window styled with a unified titlebar and inset traffic
    /// signals — including a title toolbar anchored before the window title
    /// in the titlebar and a main toolbar anchored after the window title
    /// in the titlebar.
    /// - Parameters:
    ///   - withTitle: The window title.
    ///   - contentRect: The window's main content size.
    ///   - withTitleToolbar: The window's title toolbar content view.
    ///   - contentView: The window's main content view.
    init(
        withTitle: String,
        contentRect: NSRect = CGRect(x:0, y: 0, width: 620, height: 400),
        withToolbar: @escaping () -> ToolbarContent,
        withTitleToolbar: @escaping () -> TitleToolbarContent,
        _ contentView: () -> MainContent
    ) {
        self.toolbarContent = withToolbar;
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

        //MARK: Install Toolbar AccessoryView Controllers
        
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
        DispatchQueue.main.async{
            /// First, install the title toolbar content, if any was given.
            self.installToolbarAccessory(
                position: .left,
                toolbarContent: self.titleToolbarContent);
            
            /// Next, install the main toolbar content, if any was given.
            self.installToolbarAccessory(
                position: .right,
                toolbarContent: self.toolbarContent);
        }
    }
    
    /// Install a toolbar or title toolbar accessory on the window.
    /// - Parameters:
    ///   - position: The position in the titlebar at which to install the toolbar accessory.
    ///   - toolbarContent: The SwiftUI toolbar content to install.
    internal func installToolbarAccessory<T: View>(
        position: NSLayoutConstraint.Attribute,
        toolbarContent: () -> T
    ) {
        let toolbarContentView = toolbarContent();
        if type(of: toolbar) == EmptyView.self { return }

        let accessoryView = NSHostingView(rootView: toolbarContentView);
        
        /// create the accessory at the given position -- relative to the window's title
        let accessory = NSTitlebarAccessoryViewController();
        accessory.view = accessoryView;
        accessory.layoutAttribute = position;
        
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

        /// This only applies when setting the **title** toolbar.
        if position == .left {
            toolbarTitleView.translatesAutoresizingMaskIntoConstraints  = false;
        }
        
        /// When setting the main toolbar, our view inside of `NSTitlebarAccessoryViewController`
        /// should appear after the window title and should hug the rightmost edge with a bit of
        /// padding. For the title toolbar, it should appear *before* the window title, but
        /// *after* the sidebar with slight padding on its leading edge.
        ///
        /// Both toolbars should also occupy the full height of the unified titlebar/toolbar
        /// area so that we can handle alignment in SwiftUI.
        ///
        /// For the vertical heights, we'll constrain the `NSClipView` of the accessory
        /// on `NSTitlebarContainerBlockingView`.
        ///
        /// We'll leave the leading edge on the main toolbar and the trailing edge on the title
        /// toolbar unconstrained so that they can both grow with SwiftUI-provided content.
        var clipViewConstraints = [
            /// When setting the main toolbar, it should hug the **right** edge.
            /// When setting the title toolbar, it should hug the **left** edge.
            position == .left ?
            accessoryClipView.leadingAnchor.constraint(
                equalTo: titlebarBlock.leadingAnchor,
                constant: 10)
            :accessoryClipView.trailingAnchor.constraint(
                equalTo: toolbarView.trailingAnchor,
                constant: -10),
            accessoryClipView.topAnchor.constraint(equalTo: titlebarBlock.topAnchor),
            accessoryClipView.bottomAnchor.constraint(equalTo: titlebarBlock.bottomAnchor),
        ];
        if position == .right { clipViewConstraints.append(
            accessoryClipView.leadingAnchor.constraint(
                equalTo: toolbarTitleView.trailingAnchor,
                constant: 10))}
        NSLayoutConstraint.activate(clipViewConstraints);

        /// Now, we need to constrain our `NSHostingView` to the bounds of the
        /// `NSClipView` in which it is contained. This will allow it to occupy
        /// the exact same space, and will let us handle alignment in SwiftUI.
        NSLayoutConstraint.activate([
            accessoryView.leadingAnchor.constraint(equalTo: accessoryClipView.leadingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: accessoryClipView.trailingAnchor),
            accessoryView.topAnchor.constraint(equalTo: accessoryClipView.topAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: accessoryClipView.bottomAnchor)
        ]);
        
        /// Finally, when setting the title toolbar, we must offset the window title to the
        /// trailing edge of our accessory -- such that it does not overlap.
        ///
        /// The `NSToolbarTitleView` already includes a leading edge inset, so
        /// we do not need to apply another constant here.
        if position == .left {
            NSLayoutConstraint.activate([
                toolbarTitleView.leadingAnchor.constraint(
                    equalTo: accessoryView.trailingAnchor,
                    constant: 2
                )])}
    }
    
    override var canBecomeKey: Bool {
        return true;
    }
    
    override var canBecomeMain: Bool {
        return true;
    }
}
