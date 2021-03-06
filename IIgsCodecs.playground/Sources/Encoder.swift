/*
Apple IIGS Toolbox Reference, Volume 1
Tech note FTN.C0.0001, FTN.C1.0000
Tech note IIGS #94
*/
open class IIgsCodecs
{
    public init()
    {
    }

    // Credits: Mario Patino
    // http://wsxyz.net/tohgr.html
    // The parameter srcBuf is an array of bytes; it can be from an entire file.
    open func packBytes(_ srcBuf: [UInt8]) ->[UInt8]
    {
        let kThreshold = 2
        var packedData = [UInt8]()
        var bufIndex = 0
        var currIndex = 0               // indexing byte being examined
        var bytesLeft = srcBuf.count

        // use the min size for the run length encoding buffer (IIgs tech note #94)
        var rleBuf = [UInt8](repeating: 0, count: 65)
        var rIndex = 0

        func captureSingletons(_ number: Int)
        {
            var count = number
            while count > 0
            {
                var k = count
                if k >= 64
                {
                    k = 64
                }
                rIndex = 0
                count -= k
                // flag byte (flag bits = %00)
                rleBuf[rIndex] = UInt8(k - 1)
                rIndex += 1
                while k > 0
                {
                    rleBuf[rIndex] = srcBuf[bufIndex]
                    rIndex += 1
                    bufIndex += 1
                    k -= 1
                }
                packedData.append(contentsOf: rleBuf[0..<rIndex])
            }
            
        }

        while bytesLeft > 0
        {
            var tmpIndex = currIndex
            var tmpCount = bytesLeft
            let currByte = srcBuf[tmpIndex]
            tmpIndex += 1
            // Loop to check if the byte is repeated
            tmpCount -= 1   // problem?
            while tmpCount != 0 && currByte == srcBuf[tmpIndex]
            {
                tmpIndex += 1
                tmpCount -= 1
            }

            var repeatCount = tmpIndex - currIndex
            // No encoding for 2 identical bytes in a row; treated as singletons
            if (repeatCount > kThreshold)
            {
                captureSingletons(currIndex - bufIndex)

                rIndex = 0
                if (repeatCount < 8) && (repeatCount % 4 != 0)
                {
                    // case 1: 3,5,6,7 identical bytes in a row
                    //print("RepeatNextByte 3,5,6,7 times")
                    rleBuf[rIndex] = 0x40 | UInt8(repeatCount - 1)
                    rIndex += 1
                    rleBuf[rIndex] = currByte
                    rIndex += 1
                    bytesLeft -= repeatCount
                    currIndex += repeatCount
                }
                else
                {
                    //print("Repeat4ofNextByte")
                    // case 3: multiple of 4 of a repeated byte (up to 64 x 4)
                    repeatCount /= 4;
                    if repeatCount > 64
                    {
                        repeatCount = 64
                    }

                    // flag byte (flag bits = %11)
                    rleBuf[rIndex] = 0xC0 | UInt8(repeatCount - 1)
                    rIndex += 1
                    rleBuf[rIndex] = currByte               // byte that is repeated
                    rIndex += 1
                    bytesLeft -= (repeatCount * 4)
                    currIndex += (repeatCount * 4)
                }
                packedData.append(contentsOf: rleBuf[0..<rIndex])
                bufIndex = currIndex
                continue
            } // above threshold

            // Deals with the situation in which the data has a set of 4 different bytes
            // which are repeated eg aa bb cc dd aa bb cc dd aa bb cc dd
            if bytesLeft >= 8
            {
                // prepare to scan ahead 4 byte position from where we are
                var repeatIndex = currIndex
                tmpIndex = currIndex + 4
                tmpCount = bytesLeft - 4

                // Looking for a repeating set of 4 different bytes starting 4 byte positions away
                while tmpCount != 0 && srcBuf[tmpIndex] == srcBuf[repeatIndex]
                {
                    tmpIndex += 1
                    repeatIndex += 1
                    tmpCount -= 1
                }

                repeatCount = tmpIndex - currIndex
                if repeatCount >= 8
                {
                    captureSingletons(currIndex - bufIndex)

                    rIndex = 0
                    // case 2 - handle repeats of 4 consecutive different bytes
                    repeatCount /= 4
                    if repeatCount > 64
                    {
                        repeatCount = 64
                    }
                    //print("RepeatNext4Bytes")
                    rleBuf[rIndex] = 0x80 | (UInt8(repeatCount - 1))
                    rIndex += 1
                    rleBuf[rIndex] = srcBuf[currIndex+0]
                    rIndex += 1
                    rleBuf[rIndex] = srcBuf[currIndex+1]
                    rIndex += 1
                    rleBuf[rIndex] = srcBuf[currIndex+2]
                    rIndex += 1
                    rleBuf[rIndex] = srcBuf[currIndex+3]
                    rIndex += 1
                    bytesLeft -= (repeatCount * 4)
                    currIndex += (repeatCount * 4)
                    bufIndex = currIndex
                    packedData.append(contentsOf: rleBuf[0..<rIndex])
                    continue
                }
            }

            currIndex += 1
            bytesLeft -= 1
        }

        // capture the stragglers which are singletons
        captureSingletons(currIndex - bufIndex)
        return packedData
    }
    
    // Credits: Andy McFadden - CiderPress source code (ReformatBase.cpp)
    //http://www.fadden.com/techmisc/hdc/lesson02.htm
    //http://kpreid.livejournal.com/4319.htm
    // The parameter packedData is the array of bytes encoded by the packBytes method
    open func unpackBytes(_ packedData:[UInt8]) -> [UInt8]
    {
        enum PackedFormat : UInt8
        {
            case allDifferent = 0, repeatNextByte, repeatNext4Bytes, repeat4ofNextByte
        }

        var unpackedData = [UInt8]()
        var srcLen = packedData.count
        var index = 0                           // index into array of packed bytes
        //println("\(packedData)")
        while (srcLen > 0)
        {
            let flag = packedData[index]
            index += 1
            let type = (flag & 0xc0) >> 6
            
            let count = (flag & 0x3f) + 1
            var rldBuf = [UInt8]()              // Run Len Decoder buffer
            srcLen -= 1
            if let whichFormat = PackedFormat(rawValue:type)
            {
                switch(whichFormat)
                {
                case .allDifferent:
                    //print("AllDifferent")
                    for i in 0..<Int(count)
                    {
                        rldBuf.append(packedData[index])
                        index += 1
                        srcLen -= 1
                    }
                case .repeatNextByte:
                    //print("RepeatNextByte")
                    let repeatedVal = packedData[index]
                    index += 1
                    srcLen -= 1
                    for i in 0..<Int(count)
                    {
                        rldBuf.append(repeatedVal)
                    }
                case .repeatNext4Bytes:
                    //print("RepeatNext4Bytes")
                    srcLen -= 4
                    var fourBytes = [UInt8](repeating: 0, count: 4)
                    fourBytes[0] = packedData[index]
                    index += 1
                    fourBytes[1] = packedData[index]
                    index += 1
                    fourBytes[2] = packedData[index]
                    index += 1
                    fourBytes[3] = packedData[index]
                    index += 1
                    for i in 0..<Int(count)
                    {
                        rldBuf += fourBytes
                    }
                case .repeat4ofNextByte:
                    //print("Repeat4ofNextByte")
                    let repeatedVal = packedData[index]
                    index += 1
                    srcLen -= 1
                    var fourBytes = [UInt8](repeating: 0, count: 4)
                    fourBytes[0] = repeatedVal
                    fourBytes[1] = repeatedVal
                    fourBytes[2] = repeatedVal
                    fourBytes[3] = repeatedVal
                    for i in 0..<Int(count)
                    {
                        rldBuf += fourBytes
                    }
                    /*  alternatively - NOTE: the count is quadruple
                    count *= 4
                    for var i = 0; i < Int(count); ++i
                    {
                        rldBuf.append(repeatedVal)
                    }
                    */
                    
                }
            }
            unpackedData += rldBuf
        } // while
        return unpackedData
    }
}
