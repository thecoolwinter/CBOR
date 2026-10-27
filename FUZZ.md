# Fuzzing CBOR

The `Fuzzing` target allows the library to be fuzzed using libfuzzer.

First build the package in release mode with the fuzzer and address checkers on:

```bash
swift build -c release --product Fuzzing -Xswiftc -sanitize=fuzzer -Xswiftc -DCBOR_FUZZING
```

Then run it:

```swift
mkdir -p .fuzz
mkdir -p .fuzz/new-corpus
mkdir -p .fuzz/corpus
mkdir -p .fuzz/artifacts
./.build/release/Fuzzing .fuzz/new-corpus .fuzz/corpus -max_total_time=30 -artifact_prefix=.fuzz/artifacts -jobs=12 -workers=12 -max_len=1000000 -merge=1
```

The above command will spawn 12 threads for 30 seconds and will add to the existing fuzzing corpus over time.
