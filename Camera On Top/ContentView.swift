//
//  ContentView.swift
//  Camera On Top
//
//  Created by Philippe Casgrain on 2020-10-04.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            CameraView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
