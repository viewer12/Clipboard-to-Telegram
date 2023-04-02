import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("获取 Bot Token")
                    .font(.title2)
                    .bold()
                
                Text("要获取 Bot Token，请按照以下步骤操作：")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. 打开 Telegram 并搜索 \"BotFather\"。")
                    Text("2. 向 BotFather 发送命令：/newbot。")
                    Text("3. 输入您的机器人名称。")
                    Text("4. 输入您的机器人用户名（必须以 bot 结尾）。")
                    Text("5. 您将收到一条消息，其中包含 bot token。将此 token 粘贴到应用程序中。")
                }
                .padding(.leading, 20)
                
                Divider()
                
                Text("获取 Chat ID")
                    .font(.title2)
                    .bold()
                
                Text("要获取 Chat ID，请按照以下步骤操作：")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. 打开 Telegram，并搜索并添加 IDBot。")
                    Text("2. 向 IDBot 发送命令：/getid。")
                    Text("3. 您将收到一条消息，其中包含您的 chat ID。将此 chat ID 粘贴到应用程序中。")
                }
                .padding(.leading, 20)
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
