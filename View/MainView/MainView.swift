//
//  MainView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/30/23.
//

import SwiftUI

struct MainView: View {
    @State var tabSelection: Tabs = .tab1
    var body: some View {
        NavigationView {
            TabView(selection: $tabSelection) {
                Text("Friend activities")
                    .tabItem {
                        Image(systemName: "person.3")
                        Text("Friends")
                    }
                    .tag(Tabs.tab1)
                InviteView()
                    .tabItem {
                        Image(systemName: "hand.wave.fill")
                        Text("Invite")
                }
                    .tag(Tabs.tab2)
            }
        }
    }
    enum Tabs {
        case tab1, tab2
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
