import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var isMonitoring: Bool

    init() {
        _isMonitoring = State(initialValue: UserDefaults.standard.bool(forKey: "isMonitoring"))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🚀 Clipboard to Telegram")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Bot Token:")
                        .font(.headline)

                    TextField("Enter your bot token", text: $appDelegate.botToken)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 20)
                        .padding(.trailing, 20)

                    Text("Chat ID:")
                        .font(.headline)

                    TextField("Enter your chat ID", text: $appDelegate.chatID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 20)
                        .padding(.trailing, 20)

                    Toggle(isOn: $appDelegate.isMonitoring) {
                        Text(appDelegate.isMonitoring ? "Monitoring Clipboard" : "Not Monitoring Clipboard")
                    }
                    .font(.headline)
                    .padding(.bottom)
                    .padding([.leading, .trailing], 20)
                    .onChange(of: appDelegate.isMonitoring) { value in
                        UserDefaults.standard.set(value, forKey: "isMonitoring")
                        if value {
                            appDelegate.startWatchingClipboard()
                        } else {
                            appDelegate.stopWatchingClipboard()
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Clipboard to Telegram")

            SettingsView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppDelegate())
    }
}

