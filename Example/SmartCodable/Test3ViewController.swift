
import SmartCodable

class Test3ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let dict: [String: Any] = [
            "name": "Mccc",
            "age": 200
        ]
        
        guard let model = [Model].deserialize(from: [dict, dict]) else { return }
        print(model)
    }
    
    struct Model: SmartCodable {
        
        var name: String?
    }
}



