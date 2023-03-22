//
//  AdvancedToolbarAppApp.swift
//  AdvancedToolbarApp
//
//  Created by Stephan Casas on 3/19/23.
//

import SwiftUI;
import Combine;

var MainWindow: NSWindow?;

@main
struct AdvancedToolbarApp: App {
    init() {
        MainWindow = AdvancedToolbarWindow(
            withTitle: "My Window",
            withToolbar: {HStack(spacing: 0){
                ToolbarButton(systemIcon: "eraser")
                ToolbarButton(systemIcon: "pencil")
                ToolbarButton(systemIcon: "plus")
            }},
            withTitleToolbar: {HStack(spacing: 0){
                ToolbarButton(systemIcon: "chevron.left").forTitleToolbar()
                ToolbarButton(systemIcon: "chevron.right").forTitleToolbar()
            }}){ ContentView() }
        
        MainWindow?.makeKeyAndOrderFront(nil);
        MainWindow?.center();
    }
    
    var body = EmptyScene();
}

struct EmptyScene : Scene {
    var body: some Scene {
        MenuBarExtra(isInserted: Binding.constant(false),
                     content: { EmptyView() },
                     label: {Label("", systemImage: "app")})}
}

struct ToolbarButton<LabelContent: View> : View {
    private let  label: () -> LabelContent;
    private let action: () -> Void;
    
    private var controlSize: ControlSize = .large;
    
    /// Create a toolbar button with an inferred `Image` icon from the given `systemName`.
    /// - Parameters:
    ///   - systemIcon: A member in **SF Symbols**
    ///   - action: The callback to perform when clicked.
    init(
        systemIcon: String,
        _ action: (() -> Void)? = nil
    ) where LabelContent == Image {
        self.init(
            label: { Image(systemName: systemIcon) },
            action: action ?? { print("User did click button with \(systemIcon) icon.") })
    }
    
    
    /// Create a toolbar button with a constructed label view.
    /// - Parameters:
    ///   - label: The label view content to use.
    ///   - action: The callback to perform when clicked.
    init(label: @escaping () -> LabelContent, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    
    var body: some View {
        /// Resizable items drawn as title accessories seem to struggle
        /// with a race condition. This may cause resizable content to
        /// unpredictably draw with a clipped offset.
        ///
        /// The additional horizontal padding *inside* the `HStack`
        /// seems to fix this issue, but is not necessary if the item
        /// is in its default state.
        HStack{
            Button(
                action: self.action,
                label: self.label
            )
            .controlSize(self.controlSize)
            .padding(.horizontal, self.controlSize == .regular ? 0 : 2)
        }
    }
    
    /// Use the smaller control size implemented on macOS title toolbar buttons.
    ///
    /// Main toolbar buttons implement the `.large` control size, while title toolbar
    /// buttons *usually* implement the `.regular` control size.
    ///
    /// Exceptions to this can be seen throughout macOS, so use what looks best.
    /// - Returns: A smaller version of the toolbar button.
    func forTitleToolbar() -> Self {
        var copy = self;
        copy.controlSize = .regular
        
        return copy;
    }
}
