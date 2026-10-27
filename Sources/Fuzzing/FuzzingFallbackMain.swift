#if !CBOR_FUZZING
import Foundation

@main
enum FuzzingFallbackMain {
    static func main() {
        print("This executable is a libFuzzer target.")
        print("See FUZZ.md for the fuzzing build command.")
    }
}
#endif
