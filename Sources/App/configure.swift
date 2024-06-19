
import Vapor
#if os(Linux)
import FoundationNetworking
#endif
import ICMPPing


// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    //app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.lifecycle.use(PingOnStartupLifecycle())
}

struct PingOnStartupLifecycle: LifecycleHandler {
    // prorizna: -1002233701341
    // dobrohotova: -1002247766290
    let lightObserver_Dobrohotova = LightObserver(ipV4: "176.36.6.27", chatID: "-1002247766290")
    let lightObserver_Prorizna = LightObserver(ipV4: "62.205.131.4", chatID: "-1002233701341")
    
    func didBoot(_ application: Application) throws {
        // Start the ping operation when the application is starting up
        application.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(0), delay: .seconds(120)) { task in
            lightObserver_Dobrohotova.performPing()
            lightObserver_Prorizna.performPing()
        }
        print("Ping scheduled")

        // Send notification message to Telegram Bot
        lightObserver_Prorizna.sendMessageToArtem(message: "Оповіщення світла Prorizna 👍")
        lightObserver_Dobrohotova.sendMessageToArtem(message: "Оповіщення світла Dobrohotova 👍")
    }
    
    func shutdown(_ application: Application) {
        // Perform any cleanup or shutdown tasks if needed
        print("Shutting down...")
        //lightObserver.sendMessageToTelegramBot(message: "Оповіщення відключення світла вимкнено 👎")
    }
}

class LightObserver{
    var lightIsOn = true
    var firstLaunch = true
    let ipV4: String //"176.36.6.27"//= "176.36.6.27"
    // MARK: - Chat Id of telegram channel
    let chatID: String //"-1002233701341"
    
    init(ipV4: String, chatID: String){
        self.ipV4 = ipV4
        self.chatID = chatID
    }
    
    func performPing() {
        
        let address = (try? ICMPPing.IPAddress(ipV4, type: .ipv4))!
        
        var resultICMP = ICMPPing.ping(address: address, timeout: 10)
        
        print(resultICMP)
      
        if resultICMP.responseType != .success{
            resultICMP = self.checkFailedPing(address: address)
        }
        switch resultICMP.responseType {
        case .success:
            if firstLaunch{
                firstLaunch = false
            } else if !lightIsOn {
                //sendMessageToTelegramBot(message: "Success: \(resultICMP)")
                sendMessageToTelegramBot(message: "Світло ON 🟢")
                lightIsOn = true
            }
        case .timeout:
            if firstLaunch{
                firstLaunch = false
                lightIsOn = false
            } else if lightIsOn{
                //sendMessageToTelegramBot(message: "Failure: \(resultICMP)")
                sendMessageToTelegramBot(message: "Світло OFF ❌")
                lightIsOn = false
            }
        case .unreachable:
            if firstLaunch{
                firstLaunch = false
                lightIsOn = false
            } else if lightIsOn{
                //sendMessageToTelegramBot(message: "Failure: \(resultICMP)")
                sendMessageToTelegramBot(message: "Світло OFF ❌")
                sendMessageToArtem(message: "Unreachable: \(resultICMP)")
                lightIsOn = false
            }
        case .unsupported:
            if firstLaunch{
                firstLaunch = false
                lightIsOn = false
            } else if lightIsOn{
                sendMessageToTelegramBot(message: "Світло OFF ❌")
                sendMessageToArtem(message: "Unsupported: \(resultICMP)")
                lightIsOn = false
            }
        default:
            sendMessageToArtem(message: "Unknow: \(resultICMP)")
        }
    }

    func checkFailedPing(address: ICMPPing.IPAddress, attempts: Int = 3) -> ICMPPing.Response{
        let resultICMP = ICMPPing.ping(address: address, timeout: 10)
        
        print(resultICMP)
        if resultICMP.responseType == .success || attempts == 1 {
            return resultICMP
        } else {
            return checkFailedPing(address: address, attempts: attempts - 1)
        }
    }
    
    // https://api.telegram.org/bot7495300891:AAGnICXbczTinnMeV3DA366OsW1E_KUgTG4/getUpdates
    
    func sendMessageToTelegramBot(message: String) {
        // Construct the URL for the Telegram Bot API endpoint
        let botToken = "7495300891:AAGnICXbczTinnMeV3DA366OsW1E_KUgTG4"
        //MARK: - Artem id chat
       // let chatID = "233609461"
        guard let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage?chat_id=\(chatID)&text=\(message)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create a URLSession
        let session = URLSession.shared
        
        // Create a data task
        let task = session.dataTask(with: url) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            // Check for response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            // Check if the response status code is in the success range
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP status code \(httpResponse.statusCode)")
                return
            }
            
            // Check if data is available
            guard let responseData = data else {
                print("No data received")
                return
            }
            
            // Convert the data to a string for debugging purposes
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Response: \(responseString)")
            } else {
                print("No response data")
            }
        }
        
        // Start the data task
        task.resume()
    }
    
    func sendMessageToArtem(message: String) {
        // Construct the URL for the Telegram Bot API endpoint
        let botToken = "7495300891:AAGnICXbczTinnMeV3DA366OsW1E_KUgTG4"
        //MARK: - Artem id chat
        let chatID = "233609461"
        guard let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage?chat_id=\(chatID)&text=\(message)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create a URLSession
        let session = URLSession.shared
        
        // Create a data task
        let task = session.dataTask(with: url) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            // Check for response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            // Check if the response status code is in the success range
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP status code \(httpResponse.statusCode)")
                return
            }
            
            // Check if data is available
            guard let responseData = data else {
                print("No data received")
                return
            }
            
            // Convert the data to a string for debugging purposes
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Response: \(responseString)")
            } else {
                print("No response data")
            }
        }
        
        // Start the data task
        task.resume()
    }
}


