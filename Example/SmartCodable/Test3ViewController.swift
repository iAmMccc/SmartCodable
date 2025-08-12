
import SmartCodable

class Test3ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let arr = ARTEmojiEntity.parseEmojis()
        print(arr)
    }
    
    struct Model: SmartCodable {
        
        var name: String?
    }
    
    
}



struct ARTEmojiEntity: SmartCodable, Equatable {
    
    var emojis: [EmojiItem] = [] /// 表情列表
    
    // MARK: - 表情信息结构
    struct EmojiItem: SmartCodable, Equatable {
        var identifier: String = "" /// 表情的唯一标识符，比如 ":smile:"
        var image: String = ""      /// 表情图片
    }
    
    
    static func parseEmojis() -> [String: UIImage] {
        guard let entity = ARTEmojiEntity.deserialize(from: requestJsonString()) else {
            print("Error deserializing JSON")
            return [:]
        }
        
        
        print(entity)
        
        // 将表情信息转换为 [String: UIImage] 字典
        var emojiDict: [String: UIImage] = [:]
        for emoji in entity.emojis {
            if let image = UIImage(named: emoji.image) {
                emojiDict[emoji.identifier] = image
            } else {
                print("Error loading image for identifier: \(emoji.identifier)")
            }
        }
        return emojiDict
    }
}


// MARK: - 表情数据
extension ARTEmojiEntity {
    
    static func requestJsonString() -> String {
        let jsonString = """
        {
          "emojis": [
             {"image": "zeco_emoji_001", "identifier": ":circle:"},
             {"image": "zeco_emoji_002", "identifier": ":smile:"},
             {"image": "zeco_emoji_003", "identifier": ":awkward:"},
             {"image": "zeco_emoji_004", "identifier": ":heart:"},
             {"image": "zeco_emoji_005", "identifier": ":quiet:"},
             {"image": "zeco_emoji_006", "identifier": ":surprised:"},
             {"image": "zeco_emoji_007", "identifier": ":proud:"},
             {"image": "zeco_emoji_008", "identifier": ":grin:"},
             {"image": "zeco_emoji_009", "identifier": ":naughty:"},
             {"image": "zeco_emoji_010", "identifier": ":dazed:"},
             {"image": "zeco_emoji_011", "identifier": ":arrogant:"},
             {"image": "zeco_emoji_012", "identifier": ":shock:"},
             {"image": "zeco_emoji_013", "identifier": ":blush:"},
             {"image": "zeco_emoji_014", "identifier": ":happy:"},
             {"image": "zeco_emoji_015", "identifier": ":facepalm:"},
             {"image": "zeco_emoji_016", "identifier": ":sleepy:"},
             {"image": "zeco_emoji_017", "identifier": ":sleep:"},
             {"image": "zeco_emoji_018", "identifier": ":tear:"},
             {"image": "zeco_emoji_019", "identifier": ":sad:"},
             {"image": "zeco_emoji_020", "identifier": ":cow:"},
             {"image": "zeco_emoji_021", "identifier": ":angry:"},
             {"image": "zeco_emoji_022", "identifier": ":petrified:"},
             {"image": "zeco_emoji_023", "identifier": ":snicker:"},
             {"image": "zeco_emoji_024", "identifier": ":pout:"},
             {"image": "zeco_emoji_025", "identifier": ":eyeroll:"},
             {"image": "zeco_emoji_026", "identifier": ":thank_you:"},
             {"image": "zeco_emoji_027", "identifier": ":cry:"},
             {"image": "zeco_emoji_028", "identifier": ":crazy:"},
             {"image": "zeco_emoji_029", "identifier": ":thumbs_up:"},
             {"image": "zeco_emoji_030", "identifier": ":goodbye:"},
             {"image": "zeco_emoji_031", "identifier": ":question:"},
             {"image": "zeco_emoji_032", "identifier": ":dog_head:"},
             {"image": "zeco_emoji_033", "identifier": ":yeah:"},
             {"image": "zeco_emoji_034", "identifier": ":thumbs_up_hand:"},
             {"image": "zeco_emoji_035", "identifier": ":point:"},
             {"image": "zeco_emoji_036", "identifier": ":clasped_hands:"},
             {"image": "zeco_emoji_037", "identifier": ":ok:"},
             {"image": "zeco_emoji_038", "identifier": ":handshake:"},
             {"image": "zeco_emoji_039", "identifier": ":clap:"},
             {"image": "zeco_emoji_040", "identifier": ":fist_bump:"},
             {"image": "zeco_emoji_041", "identifier": ":muscle:"},
             {"image": "zeco_emoji_042", "identifier": ":location:"},
             {"image": "zeco_emoji_043", "identifier": ":airplane:"},
             {"image": "zeco_emoji_044", "identifier": ":gift:"},
             {"image": "zeco_emoji_045", "identifier": ":graduation_cap:"},
             {"image": "zeco_emoji_046", "identifier": ":notebook:"},
             {"image": "zeco_emoji_047", "identifier": ":fire:"},
             {"image": "zeco_emoji_048", "identifier": ":money_bag:"},
             {"image": "zeco_emoji_049", "identifier": ":rich:"},
             {"image": "zeco_emoji_050", "identifier": ":cheer:"},
             {"image": "zeco_emoji_051", "identifier": ":cake:"},
             {"image": "zeco_emoji_052", "identifier": ":fireworks:"},
             {"image": "zeco_emoji_053", "identifier": ":look:"},
             {"image": "zeco_emoji_054", "identifier": ":wallet:"},
             {"image": "zeco_emoji_055", "identifier": ":star:"},
             {"image": "zeco_emoji_056", "identifier": ":rose:"},
             {"image": "zeco_emoji_057", "identifier": ":relaxed:"},
             {"image": "zeco_emoji_058", "identifier": ":parenting:"},
             {"image": "zeco_emoji_059", "identifier": ":useful:"},
             {"image": "zeco_emoji_060", "identifier": ":saved:"},
             {"image": "zeco_emoji_061", "identifier": ":seedling:"},
             {"image": "zeco_emoji_062", "identifier": ":have:"},
             {"image": "zeco_emoji_063", "identifier": ":yes:"},
             {"image": "zeco_emoji_064", "identifier": ":one:"},
             {"image": "zeco_emoji_065", "identifier": ":two:"},
             {"image": "zeco_emoji_066", "identifier": ":three:"},
             {"image": "zeco_emoji_067", "identifier": ":four:"},
             {"image": "zeco_emoji_068", "identifier": ":five:"},
             {"image": "zeco_emoji_069", "identifier": ":six:"},
             {"image": "zeco_emoji_070", "identifier": ":seven:"},
             {"image": "zeco_emoji_071", "identifier": ":eight:"},
             {"image": "zeco_emoji_072", "identifier": ":nine:"},
             {"image": "zeco_emoji_073", "identifier": ":full:"},
             {"image": "zeco_emoji_074", "identifier": ":plus_one:"},
             {"image": "zeco_emoji_075", "identifier": ":prohibited:"},
             {"image": "zeco_emoji_076", "identifier": ":yellow_heart:"},
             {"image": "zeco_emoji_077", "identifier": ":orange_heart:"},
             {"image": "zeco_emoji_078", "identifier": ":green_heart:"},
             {"image": "zeco_emoji_079", "identifier": ":dark_green_heart:"},
             {"image": "zeco_emoji_080", "identifier": ":blue_heart:"}
          ]
        }
        """
        return jsonString
    }
}

/**

 */
