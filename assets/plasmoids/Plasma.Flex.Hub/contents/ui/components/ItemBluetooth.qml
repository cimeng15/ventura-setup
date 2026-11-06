import QtQuick
import "../lib" as Lib
import "../js/funcs.js" as Funcs
import org.kde.bluezqt 1.0 as BluezQt
import org.kde.plasma.core as PlasmaCore

Item {
    property QtObject btManager : BluezQt.Manager

    property bool mouseAreaActive:  parent.mouseAreaActive

    Lib.Item {
        id: item
        width: parent.width
        height: parent.height
        activeSub: true
        smallMode: false
        isMaskIcon: true
        title: textConstants.bluetooth
        sub: Funcs.getBtDevice()
        itemIcon:  Funcs.getBtDevice() === i18n("Disabled") || Funcs.getBtDevice() === i18n("Unavailable")  ? "network-bluetooth-inactive-symbolic" : Funcs.getBtDevice() === i18n("Not Connected") ? "network-bluetooth-symbolic" : Funcs.getBtDevice() === i18n("Offline") ? "network-bluetooth-inactive-symbolic" : "network-bluetooth-activated"
        MouseArea {
            anchors.fill: parent
            enabled: mouseAreaActive
            onClicked: {
                btLauncher.connectSource("kcmshell6 kcm_bluetooth")
            }
        }
    }

    PlasmaCore.DataSource {
        id: btLauncher
        engine: "executable"
        connectedSources: []
    }
}
