cd /Users/i830671/git/SatochipSwift/Examples/Verify

xcodebuild -scheme Verify -configuration Debug -destination 'platform=iOS,id=00008030-00152548227A402E' build

xcodebuild -scheme Verify -configuration Debug -destination 'platform=iOS,id=00008030-00152548227A402E' install

xcrun devicectl device process launch --device 0EFFEADB-10B0-40D0-99D3-612568107A77 com.gammastream.VerifyPIN

xcrun devicectl device process launch --device 0EFFEADB-10B0-40D0-99D3-612568107A77 com.gammastream.VerifyPIN && log stream --predicate 'process == "Verify"' --style compact



pkill -f "log stream"