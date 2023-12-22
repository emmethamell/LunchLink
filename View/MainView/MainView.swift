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
        NavigationStack {
            TabView(selection: $tabSelection) {
                FriendsView()
                    .tabItem {
                        Image(systemName: "person.3")
                        Text("Friends")
                    }

                    .tag(Tabs.tab1)
                InviteView{_ in}
                    .tabItem {
                        Image(systemName: "hand.wave.fill")
                        Text("Invite")
                }
                    .tag(Tabs.tab2)
            }
            .onAppear {
                            //correct the transparency bug for Tab bars
                            let tabBarAppearance = UITabBarAppearance()
                            tabBarAppearance.configureWithOpaqueBackground()
                            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                            //correct the transparency bug for Navigation bars
                            let navigationBarAppearance = UINavigationBarAppearance()
                            navigationBarAppearance.configureWithOpaqueBackground()
                            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
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
