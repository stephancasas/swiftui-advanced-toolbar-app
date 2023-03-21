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
            withTitleToolbar: {
                HStack{
                    Button(
                        action: { print("User did navigate backward.") },
                        label: { Image(systemName: "chevron.left") })
                    Button(
                        action: { print("User did navigate forward.") },
                        label: { Image(systemName: "chevron.right") })
                }.padding(.horizontal, 3)
            }){ ContentView() }
        
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
