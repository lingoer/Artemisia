//
//  ContentView.swift
//  ArteExample
//
//  Created by Aemaeth on 2020/11/16.
//

import SwiftUI
import Artemisia
import Combine
import AudioUnit

protocol MQTTJSON: TransmittableByMQTT, Codable {
}
extension MQTTJSON{
    static func fromMessage(message: Mosquitto.Message) -> Self {
        
        try! JSONDecoder().decode(self, from: message.payload)
    }
    func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message {
        .message(try! JSONEncoder().encode(self))
    }
}

struct Message: MQTTJSON {
    let sender: String
    let content: String
}

class ViewModel: ObservableObject {
    
    typealias Input = Message
    typealias Failure = Never
    

    @Published var messages: [Message] = []
    @Published var connected: Bool = false
    let arte = Artemisia(host: "test.mosquitto.org", version: .v5)
    var bag:[AnyCancellable] = []
    var txt: String = "hello"
    
    init(topic: String) {
//        arte
        arte[topic].sink { (message:Message) in
            self.messages.append(message)
        }.store(in: &bag)
    }
}

struct MQTTView: View {

    @StateObject var viewmodel: ViewModel = ViewModel(topic: "")
    var body: some View{
        Text(viewmodel.txt)
    }

}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
    }
}
