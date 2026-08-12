import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let appGroupId = "group.com.nhanchaukp.fcode.pos"
            let sharedDefaults = UserDefaults(suiteName: appGroupId)
            
            // 1. Đọc tên file sound người dùng đã chọn từ App Group UserDefaults
            let savedSoundName = sharedDefaults?.string(forKey: "selected_notification_sound_filename")
            
            // 2. Hoặc từ userInfo payload nếu server truyền custom_sound / sound_name
            let payloadSoundName = request.content.userInfo["custom_sound"] as? String 
                ?? request.content.userInfo["sound_name"] as? String
            
            let soundFileName = (savedSoundName != nil && !savedSoundName!.isEmpty && savedSoundName != "default") 
                ? savedSoundName! 
                : (payloadSoundName ?? "default")
            
            if soundFileName != "default" && !soundFileName.isEmpty {
                // Thay đổi notification sound phát âm thanh người dùng đã chọn ngầm
                bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFileName))
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
