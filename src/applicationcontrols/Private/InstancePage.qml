import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import Machinekit.Controls 1.0
import Machinekit.Service 1.0

Item {
    property bool autoSelectInstance: false
    property var launcherService: {"items": []}
    property var serviceDiscovery: {"lookupMode": ServiceDiscovery.MulticastDNS}

    signal nameServersChanged()

    id: root
    width: 1000
    height: 800

    signal instanceSelected(int index)

    Button {
        id: dummyButton
        visible: false
    }
    Label {
        id: dummyText
        visible: false
    }

    Component {
        id: instanceListView

        ListView {
            spacing: Screen.logicalPixelDensity*3
            clip: true

            model: launcherService.items
            delegate: Button {
                anchors.left: parent.left
                anchors.right: parent.right
                height: dummyButton.height * 3

                Label {
                    id: titleText2

                    anchors.fill: parent
                    font.pointSize: dummyText.font.pointSize*1.3
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: name
                    elide: Text.ElideRight
                }

                onClicked: instanceSelected(index)
            }

            onCountChanged: {
                if (root.visible && (autoSelectInstance == true) && (count > 0))
                {
                    instanceSelected(0)
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: true
                visible: launcherService.items.length === 0
                height: parent.height * 0.15
                width: height
            }
        }
    }

    SlideView {
        id: discoveryView
        anchors.fill: parent

        onCurrentIndexChanged: {
            if (currentIndex == 0)
                serviceDiscovery.lookupMode = ServiceDiscovery.MulticastDNS
            else
                serviceDiscovery.lookupMode = ServiceDiscovery.UnicastDNS
        }

        Binding {
            target: discoveryView; property: "currentIndex";
            value: (serviceDiscovery.lookupMode === ServiceDiscovery.MulticastDNS) ? 0 : 1
        }

        SlidePage {
            title: qsTr("Multicast")

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Screen.logicalPixelDensity*3
                spacing: Screen.logicalPixelDensity*3

                Label {
                    id: pageTitleText2

                    Layout.fillWidth: true
                    text: qsTr("Available Instances:")
                    font.pointSize: dummyText.font.pointSize * 1.3
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    sourceComponent: instanceListView
                    active: true
                }
            }
        }

        SlidePage {
            id: unicastPage
            title: qsTr("Unicast")

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Screen.logicalPixelDensity*3
                spacing: Screen.logicalPixelDensity*3

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Available Instances:")
                    font.pointSize: dummyText.font.pointSize * 1.3
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    sourceComponent: instanceListView
                    active: true
                }

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Machinekit Instances:")
                    font.pointSize: dummyText.font.pointSize * 1.3
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                ListView {
                    id: dnsServerView
                    Layout.fillWidth: true
                    Layout.preferredHeight: dummyButton.height * 1.5 * model.length + Screen.logicalPixelDensity * 1.5 * Math.max(model.length-1, 0)
                    spacing: Screen.logicalPixelDensity*1.5

                    model: serviceDiscovery.nameServers

                    delegate: RowLayout {
                                id: viewItem
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: dummyButton.height * 1.5

                                Label {
                                    text: qsTr("Instance ") + (index + 1) + ":"
                                    font.pointSize: dummyText.font.pointSize * 1.2
                                }

                                TextField {
                                    id: dnsServerTextField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    font.pointSize: dummyText.font.pointSize * 1.2
                                    placeholderText: qsTr("IP address or hostname")
                                    onEditingFinished: {
                                        dnsServerView.model[index].hostName = text
                                        serviceDiscovery.updateNameServers()
                                        root.nameServersChanged()

                                        root.forceActiveFocus()   // remove the focus
                                    }

                                    Binding {
                                        target: dnsServerTextField;
                                        property: "text";
                                        value: (dnsServerView.model[index] !== null) ? dnsServerView.model[index].hostName : ""
                                    }
                                }

                                Button {
                                    Layout.fillHeight: true
                                    text: (dnsServerTextField.text !== "") ? "+" : "-"
                                    visible: (index === (dnsServerView.model.length - 1)) && (index < 2)   // last item, limited to 3 items due to bug => TODO
                                    onClicked: {
                                        root.forceActiveFocus()   // accept changes on text edit

                                        if (dnsServerTextField.text && dnsServerView.model[index].hostName)
                                        {
                                            var nameServerObject = nameServerComponent.createObject(root, {})
                                            serviceDiscovery.addNameServer(nameServerObject)
                                        }
                                    }

                                    Label {
                                        anchors.fill: parent
                                        font.pointSize: dummyText.font.pointSize*1.2
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: "+"
                                    }
                                }
                            }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dummyButton.height * 1.5
                    visible: dnsServerView.model.length === 0
                    onClicked: {
                        serviceDiscovery.addNameServer(nameServerComponent.createObject(root, {}))
                    }

                    Label {
                        anchors.fill: parent
                        font.pointSize: dummyText.font.pointSize*1.2
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "+"
                    }
                }
            }
        }
    }
}

