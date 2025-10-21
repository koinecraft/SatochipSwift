### Steps to build, run, and test the Simple example

cd /Users/i830671/git/SatochipSwift/Examples/Simple

xcodebuild -scheme Simple -configuration Debug -destination 'platform=iOS,id=00008030-00152548227A402E' build

xcodebuild -scheme Simple -configuration Debug -destination 'platform=iOS,id=00008030-00152548227A402E' install

xcrun devicectl device process launch --device 0EFFEADB-10B0-40D0-99D3-612568107A77 com.gammastream.SimpleSato

xcrun devicectl device process launch --device 0EFFEADB-10B0-40D0-99D3-612568107A77 com.gammastream.SimpleSato && log stream --predicate 'process == "Simple"' --style compact



pkill -f "log stream"


log stream --predicate 'process == "Simple"' --style compact
log stream --predicate 'process == "Simple"' --style compact