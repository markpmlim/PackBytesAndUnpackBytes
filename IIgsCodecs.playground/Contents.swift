//: Playground - noun: a place where people can play
import Foundation

// Updated to Swift 3.x

let myBundle = Bundle.main
var pathToFile = myBundle.path(forResource: "CLOWN", ofType:"SHR")
if let fileData = try? Data(contentsOf: URL(fileURLWithPath: pathToFile!))
{
    let fileLength = fileData.count
    print("file size:\(fileLength)")
    var src = [UInt8](repeating: 0, count: fileLength)
    (fileData as NSData).getBytes(&src, length:fileLength)
    let encoder = IIgsCodecs()
    var unpackedData = encoder.packBytes(src)
    let dataContents = Data(bytes: &unpackedData, count:unpackedData.count)
    print("unpacked size:\(unpackedData.count)")
    var destPath: NSString = "~/Documents/Shared Playground Data/CLOWN.PAK"
    destPath = destPath.expandingTildeInPath as NSString
    try? dataContents.write(to: URL(fileURLWithPath: destPath as String), options: [.atomic])
}
else
{
    print("File processing failed!")
}

pathToFile = myBundle.path(forResource: "TAJ", ofType:"PAK")

if let fileData = try? Data(contentsOf: URL(fileURLWithPath: pathToFile!))
{
    let fileLength = fileData.count
    print("file size:\(fileLength)")
    var src = [UInt8](repeating: 0, count: fileLength)
    (fileData as NSData).getBytes(&src, length:fileLength)
    let decoder = IIgsCodecs()
    var unpackedData = decoder.unpackBytes(src)
    let dataContents = Data(bytes: &unpackedData, count:unpackedData.count)
    print("packed size:\(unpackedData.count)")
    var destPath: NSString = "~/Documents/Shared Playground Data/TAJ.SHR"
    destPath = destPath.expandingTildeInPath as NSString
    try? dataContents.write(to: URL(fileURLWithPath: destPath as String), options: [.atomic])

}
