//
//  ContentView.swift
//  AdvancedToolbarApp
//
//  Created by Stephan Casas on 3/19/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            List{
                NavigationLink(destination: {
                    Text("Pictures").onAppear{ MainWindow?.title = "Pictures" }
                }, label: {
                    Label("Pictures", systemImage: "photo.on.rectangle")
                })
                
                NavigationLink(destination: {
                    Text("Videos").onAppear{ MainWindow?.title = "Videos" }
                }, label: {
                    Label("Videos", systemImage: "film.stack")
                })
                
                NavigationLink(destination: {
                    Text("Documents").onAppear{ MainWindow?.title = "Documents" }
                }, label: {
                    Label("Documents", systemImage: "doc")
                })
            }.listStyle(.sidebar)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
