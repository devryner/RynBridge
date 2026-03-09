#if canImport(UIKit)
import KakaoSDKCommon

public enum KakaoSDKInitializer {
    public static func initSDK(appKey: String) {
        KakaoSDK.initSDK(appKey: appKey)
    }
}
#endif
