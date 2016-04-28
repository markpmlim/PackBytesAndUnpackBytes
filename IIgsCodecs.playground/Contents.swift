//: Playground - noun: a place where people can play
import Foundation

// Developed with XCode 7.01

let myBundle = NSBundle.mainBundle()
var pathToFile = myBundle.pathForResource("CLOWN", ofType:"SHR")
let comps = ["/Users", "marklim", "documents"]
let nsstr = NSString.pathWithComponents(comps)
if let fileData = NSData(contentsOfFile: pathToFile!)
{
	let fileLength = fileData.length
	print("file size:\(fileLength)")
	var src = [UInt8](count:fileLength, repeatedValue:0)
	fileData.getBytes(&src, length:fileLength)
	let encoder = IIgsCodecs()
	var unpackedData = encoder.packBytes(src)
	let dataContents = NSData(bytes:&unpackedData, length:unpackedData.count)
	print("unpacked size:\(unpackedData.count)")
	var destPath: NSString = "~/Documents/Shared Playground Data/CLOWN.PAK"
	destPath = destPath.stringByExpandingTildeInPath
	dataContents.writeToFile(destPath as String, atomically:true)
}
else
{
	print("File processing failed!")
}

pathToFile = myBundle.pathForResource("TAJ", ofType:"PAK")

if let fileData = NSData(contentsOfFile: pathToFile!)
{
	let fileLength = fileData.length
	print("file size:\(fileLength)")
	var src = [UInt8](count:fileLength, repeatedValue:0)
	fileData.getBytes(&src, length:fileLength)
	let decoder = IIgsCodecs()
	var unpackedData = decoder.unpackBytes(src)
	let dataContents = NSData(bytes:&unpackedData, length:unpackedData.count)
	print("packed size:\(unpackedData.count)")
	var destPath: NSString = "~/Documents/Shared Playground Data/TAJ.SHR"
	destPath = destPath.stringByExpandingTildeInPath
	dataContents.writeToFile(destPath as String, atomically:true)

}
