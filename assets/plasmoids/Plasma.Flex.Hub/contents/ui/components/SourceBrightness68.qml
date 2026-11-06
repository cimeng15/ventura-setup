import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.kitemmodels as KItemModels

// Komponen pengganti SourceBrightness.qml untuk Plasma 6.8+
// NightLightControl sudah dihapus dari Plasma 6.x, jadi bagian nightlight di-stub.
Item {
    id: root

    ScreenBrightnessControl {
        id: systemBrightnessControl
        isSilent: false
    }

    // ---- dipakai hub ----
    readonly property bool active: systemBrightnessControl.isBrightnessAvailable
    property int realValueSlider: 0
    property var mainScreen: ({ displayName: "", label: "", brightness: 0, maxBrightness: 10000 })
    readonly property var valueSlider: Math.round((mainScreen.brightness / Math.max(1, mainScreen.maxBrightness)) * 100)
    readonly property var maxSlider: 100
    readonly property int brightnessMin: 1

    // ---- stub nightlight (tidak tersedia di Plasma 6.8) ----
    signal nightMode
    onNightMode: {}
    property bool runningNightToggle: false
    property int currentTemperature: 6500
    property int targetTemperature: 6500
    property int mode: 3
    property bool inhibited: true
    property bool inhibitedFromApplet: false

    function _refresh() {
        const m = systemBrightnessControl.displays;
        if (!m || m.rowCount() === 0) return;
        const idx = m.index(0, 0);
        const role = (n) => m.KItemModels.KRoleNames.role(n);
        root.mainScreen = {
            displayName: m.data(idx, role("displayName")),
            label: m.data(idx, role("label")),
            brightness: m.data(idx, role("brightness")),
            maxBrightness: m.data(idx, role("maxBrightness"))
        };
    }

    Component.onCompleted: _refresh()

    Connections {
        target: systemBrightnessControl.displays
        function onDataChanged() { root._refresh() }
        function onModelReset() { root._refresh() }
        function onRowsInserted() { root._refresh() }
        function onRowsRemoved() { root._refresh() }
    }

    onRealValueSliderChanged: {
        const max = Math.max(1, mainScreen.maxBrightness);
        systemBrightnessControl.setBrightness(mainScreen.displayName,
            Math.round((realValueSlider / 100) * max));
    }
}
