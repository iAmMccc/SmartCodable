
import SmartCodable

class Test3ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let father = Model()
     
        let dict = father.toDictionary(useMappedKeys: true)
        print(dict)
    }
   
    
    struct Model: SmartCodable {
//        var name: String = "Mccc"
        @IgnoredKey(isEncodable: true)
        var age: Int = 29
        
        static func mappingForKey() -> [SmartKeyTransformer]? {
            [
                CodingKeys.age <--- "subAge"
            ]
        }
        
//        static func mappingForValue() -> [SmartValueTransformer]? {
//            [
//                CodingKeys.age <--- Tranformer()
//            ]
//        }
    }
    
    
    struct Tranformer: ValueTransformable {
        func transformFromJSON(_ value: Any) -> Int? {
            return nil
        }
        
        func transformToJSON(_ value: Int) -> Int? {
            return 100
        }
        

        
        
        typealias Object = Int
        
        typealias JSON = Int
    }
}



