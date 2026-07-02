//  ____                               _      ____               _           _       _          _
// / ___|   _ __ ___     __ _   _ __  | |_   / ___|   ___     __| |   __ _  | |__   | |   ___  | |
// \___ \  | '_ ` _ \   / _` | | '__| | __| | |      / _ \   / _` |  / _` | | '_ \  | |  / _ \ | |
//  ___) | | | | | | | | (_| | | |    | |_  | |___  | (_) | | (_| | | (_| | | |_) | | | |  __/ |_|
// |____/  |_| |_| |_|  \__,_| |_|     \__|  \____|  \___/   \__,_|  \__,_| |_.__/  |_|  \___| (_)
//


public typealias SmartCodableX = SmartDecodable & SmartEncodable

// Used for generic parsing.
// SmartDecodable and SmartEncodable both inherit from SmartMappable. Swift does
// not infer this Array extension's conditional conformance to inherited
// protocols, so the shared mapping protocol must be listed explicitly with the
// same Element constraint.
extension Array: SmartMappable, SmartCodableX where Element: SmartCodableX { }
