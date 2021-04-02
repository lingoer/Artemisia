//
//  ContentView.swift
//  Shared
//
//  Created by Aemaeth on 2020/11/18.
//

import SwiftUI
import Combine
import Artemisia

struct Model: Codable, Identifiable {
  let sender: String
  let text: String
  var id: String { text + sender }
}

extension Model: MQTTTransmittable {
  func toMessage(options defaultOptions: Mosquitto.PublishOptions) -> Mosquitto.Message {
    .message(try! JSONEncoder().encode(self), options: defaultOptions)
  }
  static func fromMessage(message: Mosquitto.Message) -> Model {
    try! JSONDecoder().decode(self, from: message.payload)
  }
}

class ViewModel: ObservableObject {
  
  let client = Artemisia.connect(host: "broker.emqx.io", version: .v5)
  @Published
  var receivedItems: [Model] = []
  var text: String = ""
  var bag:[AnyCancellable] = []
  let label:String
  
  init(label: String) {
    self.label = label
    client[label]
      .receive(on: RunLoop.main)
      .sink {[weak self] (item:Model) in
        self?.receivedItems.append(item)
      }.store(in: &bag)
    
  }
  func send() {
    client[label].publish(message: Model(sender: "artemisia", text: text))
    text = ""
  }
}

struct ContentView: View {
  @StateObject
  var viewmodel: ViewModel = ViewModel(label: "aemaeth/topicit")
  
  var body: some View {
    VStack(alignment: .center, content: {
      List(viewmodel.receivedItems) { (item:Model) in
        HStack(alignment: .center, content: {
          Text("\(item.sender): \(item.text)")
        })
      }
      HStack(alignment: .center, content: {
        TextField("Text to send", text: $viewmodel.text)
        Button(action: viewmodel.send, label: {
          Text("Send")
        })
      }).padding()
    }).frame(minWidth: 600, idealWidth: 600, maxWidth: .infinity, minHeight: 400, idealHeight: 400, maxHeight: .infinity, alignment: .center)
    .textFieldStyle(RoundedBorderTextFieldStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .previewLayout(.sizeThatFits)
  }
}

