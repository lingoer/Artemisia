//
//  ContentView.swift
//  Shared
//
//  Created by Aemaeth on 2020/11/18.
//

import SwiftUI
import Combine
import Artemisia

struct Model: Codable {
    let sender: String
    let text: String
}

extension Model: MQTTTransmittable {
    func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message {
        .message(try! JSONEncoder().encode(self), options: defaultOptions)
//        try! JSONEncoder().encode(self).toMessage(options: defaultOptions)
    }
    static func fromMessage(message: Mosquitto.Message) -> Model {
        try! JSONDecoder().decode(self, from: message.payload)
    }
}

class ViewModel: ObservableObject {

    let client = Artemisia.connect(host: "broker.emqx.io")
    @Published var receivedItems: [Model] = []
    var text: String = ""
    var bag:[AnyCancellable] = []
    let label:String
    
    init(label: String) {
        self.label = label
        client[label].sink {[self] (item:Model) in
            receivedItems.append(item)
        }.store(in: &bag)

    }
    func send() {
        let d = try! JSONEncoder().encode(Model(sender: label, text: text))
        let s = String(data: d, encoding: .utf8)!
        print(s)
        client[label].publish(message: s)
    }
}

struct ContentView: View {
    @StateObject var viewmodel: ViewModel = ViewModel(label: "aemaeth/topicit")
    
    var body: some View {
        VStack(alignment: .center, content: {
            List(viewmodel.receivedItems, id: \.text) { (item:Model) in
                HStack(alignment: .center, content: {
                    Text(item.text)
                    Text(item.sender)
                })
            }
            HStack(alignment: .center, content: {
                TextField("Text to send", text: $viewmodel.text)
                Button(action: viewmodel.send, label: {
                    Text("Send")
                })
            })
        }).textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
