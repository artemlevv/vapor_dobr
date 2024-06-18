
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
    let lightObserver = LightObserver()
    func didBoot(_ application: Application) throws {
        // Start the ping operation when the application is starting up
        application.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(0), delay: .seconds(120)) { task in
            lightObserver.performPing()
        }
        print("Ping scheduled")

        // Send notification message to Telegram Bot
        lightObserver.sendMessageToTelegramBot(message: "Оповіщення відключення світла ввімкнено 👍")
    }
    
    func shutdown(_ application: Application) {
        // Perform any cleanup or shutdown tasks if needed
        print("Shutting down...")
        lightObserver.sendMessageToTelegramBot(message: "Оповіщення відключення світла вимкнено 👎")
    }
}


class LightObserver{
    var lightIsOn = true
    var firstLaunch = true
    let ipV4 = "176.36.6.27"
    
    func performPing() {
        
        let address = (try? ICMPPing.IPAddress(ipV4, type: .ipv4))!
        
        let resultICMP = ICMPPing.ping(address: address, timeout: 10)
        
       // print(resultICMP)
      //  print("ISSuccess: \(resultICMP.responseType == .success)")
        switch resultICMP.responseType {
        case .success:
            if firstLaunch{
                firstLaunch = false
            } else if !lightIsOn {
                //sendMessageToTelegramBot(message: "Success: \(resultICMP)")
                sendMessageToTelegramBot(message: "⚡ Світло повернулося ⚡")
                lightIsOn = true
            }
        case .timeout:
            if firstLaunch{
                firstLaunch = false
                lightIsOn = false
            } else if lightIsOn{
                //sendMessageToTelegramBot(message: "Failure: \(resultICMP)")
                sendMessageToTelegramBot(message: "❌ Світло зникло ❌")
                lightIsOn = false
            }
        case .unreachable:
            if firstLaunch{
                firstLaunch = false
                lightIsOn = false
            } else if lightIsOn{
                //sendMessageToTelegramBot(message: "Failure: \(resultICMP)")
                sendMessageToTelegramBot(message: "❌ Світло зникло ❌")
                lightIsOn = false
            }
        default:
            sendMessageToArtem(message: "Unknow: \(resultICMP)")
        }
    }
    
    
    func sendMessageToTelegramBot(message: String) {
        // Construct the URL for the Telegram Bot API endpoint
        let botToken = "7495300891:AAGnICXbczTinnMeV3DA366OsW1E_KUgTG4"
        //MARK: - Dobro_Home id chat
        let chatID = "-1002247766290"
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
        //MARK: - Dobro_Home id chat
        // let chatID = "-1002247766290" this is group ID
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


/*

enum PingResult {
    case success
    case failure
}
*/


/*func pingIPv4(address: String) -> PingResult {
 /* let task = Process()
  
  #if os(Linux)
  task.executableURL = URL(fileURLWithPath: "/bin/ping")
  #else
  task.launchPath = "/sbin/ping"
  #endif
  
  task.arguments = ["-c", "4", address]
  
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = pipe
  
  task.launch()
  task.waitUntilExit()
  
  let status = task.terminationStatus
  if status == 0 {
  return .success
  } else {
  return .failure
  }*/
 return .success
 }*/

/*
 
 func performPing() {
     /*let maxAttempts = 5
      let intervalInSeconds = 2
      var attempt = 0*/
     let ipV4 = "176.36.6.27"
     
     let address = (try? ICMPPing.IPAddress(ipV4, type: .ipv4))!
     
     let resultICMP = ICMPPing.ping(address: address, timeout: 10)
     
     print(resultICMP)
     print("ISSuccess: \(resultICMP.responseType == .success)")
     switch resultICMP.responseType {
     case .success:
         if firstLaunch{
             firstLaunch = false
         } else if !lightIsOn {
             //sendMessageToTelegramBot(message: "Success: \(resultICMP)")
             sendMessageToTelegramBot(message: "⚡ Світло повернулося ⚡")
             lightIsOn = true
         }
     case .timeout:
         if firstLaunch{
             firstLaunch = false
             lightIsOn = false
         } else if lightIsOn{
             //sendMessageToTelegramBot(message: "Failure: \(resultICMP)")
             sendMessageToTelegramBot(message: "❌ Світло зникло ❌")
             lightIsOn = false
         }
     default:
         sendMessageToArtem(message: "Unknow: \(resultICMP)")
     }
     
     /*func pingWithRetry() {
      attempt += 1
      let address = (try? ICMPPing.IPAddress("176.36.6.27", type: .ipv4))!
      
      let resultICMP = ICMPPing.ping(address: address)
      
      print(resultICMP)
      print("ISSuccess: \(resultICMP.responseType == .success)")
      /* let result = pingIPv4(address: ipV4)
       switch result {
       case .success:
       print("Ping successful")
       if !lightIsOn{
       lightIsOn = true
       sendMessageToTelegramBot(message: "⚡ Світло повернулося ⚡")
       }
       case .failure:
       print("Ping failed")
       if lightIsOn{
       if attempt < maxAttempts {
       print("Retrying in \(intervalInSeconds) seconds...")
       print("Atempt made: \(attempt)")
       DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(intervalInSeconds)) {
       pingWithRetry()
       }
       } else if lightIsOn{
       print("Reached maximum number of attempts. Port down.")
       lightIsOn = false
       sendMessageToTelegramBot(message: "❌ Світло зникло ❌")
       }
       }
       }*/
      }*/
     
     //MARK: - need to rety
     // pingWithRetry()
 }
 */
