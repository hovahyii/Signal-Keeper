@tool
extends EditorPlugin

var exporter: EditorExportPlugin

func _enter_tree() -> void:
    exporter = PetalExport.new()
    add_export_plugin(exporter)

func _exit_tree() -> void:
    remove_export_plugin(exporter)

class PetalExport extends EditorExportPlugin:
    func _get_name() -> String:
        return "SignalKeeperPetalAds"

    func _supports_platform(platform: EditorExportPlatform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
        return PackedStringArray(["com.huawei.hms:ads-lite:13.4.90.300"])

    func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
        return PackedStringArray(["https://developer.huawei.com/repo/"])

    func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
        return '<meta-data android:name="org.godotengine.plugin.v2.PetalAds" android:value="com.hovahdigitalsolutions.signalkeeper.ads.PetalAds" /><meta-data android:name="com.huawei.hms.client.appid" android:value="appid=119227547" />'
