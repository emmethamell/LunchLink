//
//  ContentView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/22/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        // redirect ther user based on log status
        if logStatus{
            MainView()
        } else {
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
