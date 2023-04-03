//
//  ClipboardToTelegramApp.swift
//  ClipboardToTelegram
//
//  Created by Apple on 2023/3/31.
//
import AppKit
import SwiftUI
import CoreImage
import Cocoa
import UniformTypeIdentifiers

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject var appDelegate = AppDelegate()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)

        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var isMonitoring: Bool = false
    var timer: Timer?

    @Published var botToken: String {
            didSet {
                UserDefaults.standard.set(botToken, forKey: "botToken")
            }
        }
    @Published var chatID: String {
            didSet {
                UserDefaults.standard.set(chatID, forKey: "chatID")
            }
        }
    @Published var monitoringEnabled: Bool = false {
        didSet {
            if monitoringEnabled {
                startWatchingClipboard()
            } else {
                stopWatchingClipboard()
            }
        }
    }

        override init() {
            botToken = UserDefaults.standard.string(forKey: "botToken") ?? ""
            chatID = UserDefaults.standard.string(forKey: "chatID") ?? ""
            super.init()
        }

    func startWatchingClipboard() {
        if timer != nil {
            return
        }

        let pasteboard = NSPasteboard.general
        var changeCount: Int = pasteboard.changeCount
        var lastText: String? = nil
        var lastImage: NSImage? = nil
        var lastFileUrl: URL? = nil

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isMonitoring else {
                return
            }

            print("Checking clipboard...")
            if pasteboard.changeCount != changeCount {
                print("Clipboard content changed")
                changeCount = pasteboard.changeCount
                
                if let pasteboardString = pasteboard.string(forType: .string) {
                    if pasteboardString != lastText {
                        lastText = pasteboardString
                        self.sendTextToTelegramBot(text: pasteboardString)
                    }
                } else if let pasteboardImage = NSImage(pasteboard: pasteboard) {
                    if let last = lastImage, let pngData1 = pasteboardImage.tiffRepresentation, let pngData2 = last.tiffRepresentation, pngData1 == pngData2 {
                        // Do nothing, as the images are the same
                    } else {
                        lastImage = pasteboardImage
                        self.sendImageToTelegramBot(image: pasteboardImage)
                    }
                } else if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let fileURL = fileURLs.first {
                    if fileURL != lastFileUrl {
                        lastFileUrl = fileURL
                        do {
                            let fileData = try Data(contentsOf: fileURL)
                            let mimeType = fileURL.mimeType()
                            self.sendFileToTelegramBot(file: fileData, fileName: fileURL.lastPathComponent, mimeType: mimeType)
                        } catch {
                            print("Error reading file:", error)
                        }
                    }
                }
            }
        }
    }


    func stopWatchingClipboard() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    

        func updateSettings(botToken: String, chatID: String) {
            self.botToken = botToken
            self.chatID = chatID
        }
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        }
    func sendTextToTelegramBot(text: String) {
        let monospaceText = "```\n\(text)\n```"
        let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage?chat_id=\(chatID)&text=\(monospaceText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&parse_mode=MarkdownV2"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { _, _, _ in
        }.resume()

        print("Sending text message to Telegram bot: \(text)")
    }
    
    func sendImageToTelegramBot(image: NSImage) {
        guard let imageData = image.pngData() else { return }
        self.sendFileToTelegramBot(file: imageData, fileName: "image.png", mimeType: "image/png")
        print("Sending image message to Telegram bot.")
    }


    
    func sendFileToTelegramBot(file: Data, fileName: String, mimeType: String) {
        let urlString = "https://api.telegram.org/bot\(botToken)/sendDocument"
        let url = URL(string: urlString)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(chatID)\r\n".data(using: .utf8)!)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        
        if mimeType.starts(with: "image/") {
            request.setValue("multipart/form-data; name=\"photo\"; filename=\"\(fileName)\"", forHTTPHeaderField: "Content-Disposition")
        } else {
            request.setValue("multipart/form-data; name=\"document\"; filename=\"\(fileName)\"", forHTTPHeaderField: "Content-Disposition")
        }
        
        data.append("Content-Disposition: form-data; name=\"document\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(file)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: data) { (data, response, error) in
            if let error = error {
                print("Error sending file to Telegram bot:", error)
            } else {
                print("File sent successfully to Telegram bot")
            }
        }
        task.resume()
    }

    
    }




extension URL {
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        if let utType = UTType(filenameExtension: pathExtension) {
            if let mimeType = utType.preferredMIMEType {
                return mimeType
            }
        }
        return "application/octet-stream"
    }
}




extension NSImage {
    func pngData() -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        guard let imageData = nsImage.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: imageData) else { return nil }
        return imageRep.representation(using: .png, properties: [:])
    }
}
