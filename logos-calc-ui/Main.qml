import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    // State
    property string result: ""
    property string errorText: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Title ──────────────────────────────────────────────
        Text {
            text: "Logos Calculator"
            font.pixelSize: 20
            font.weight: Font.DemiBold
            color: "#1f2328"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "QML frontend for the calc_module (libcalc C library)"
            font.pixelSize: 13
            color: "#57606a"
            Layout.alignment: Qt.AlignHCenter
        }

        // ── Two-operand section ────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: twoOpColumn.implicitHeight + 32
            color: "#f6f8fa"
            radius: 8
            border.color: "#d1d9e0"
            border.width: 1

            ColumnLayout {
                id: twoOpColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Two-operand operations"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#1f2328"
                }

                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    TextField {
                        id: inputA
                        placeholderText: "a"
                        Layout.preferredWidth: 100
                        validator: IntValidator {}
                    }

                    TextField {
                        id: inputB
                        placeholderText: "b"
                        Layout.preferredWidth: 100
                        validator: IntValidator {}
                    }

                    Button {
                        text: "Add"
                        onClicked: callTwoOp("add", inputA.text, inputB.text)

                        background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 36
                            color: parent.pressed ? "#1a7f37" : "#238636"
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Multiply"
                        onClicked: callTwoOp("multiply", inputA.text, inputB.text)

                        background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 36
                            color: parent.pressed ? "#1a7f37" : "#238636"
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // ── Single-operand section ─────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: oneOpColumn.implicitHeight + 32
            color: "#f6f8fa"
            radius: 8
            border.color: "#d1d9e0"
            border.width: 1

            ColumnLayout {
                id: oneOpColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Single-operand operations"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#1f2328"
                }

                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    TextField {
                        id: inputN
                        placeholderText: "n"
                        Layout.preferredWidth: 100
                        validator: IntValidator { bottom: 0 }
                    }

                    Button {
                        text: "Factorial"
                        onClicked: callOneOp("factorial", inputN.text)

                        background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 36
                            color: parent.pressed ? "#0a58ca" : "#0969da"
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Fibonacci"
                        onClicked: callOneOp("fibonacci", inputN.text)

                        background: Rectangle {
                            implicitWidth: 80
                            implicitHeight: 36
                            color: parent.pressed ? "#0a58ca" : "#0969da"
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // ── Info section ───────────────────────────────────────
        Button {
            text: "Get libcalc version"
            onClicked: callNoArg("libVersion")

            background: Rectangle {
                implicitWidth: 160
                implicitHeight: 36
                color: parent.pressed ? "#32383f" : "#24292f"
                radius: 6
            }
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // ── Result display ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: root.errorText.length > 0 ? "#fff1f0" : "#dafbe1"
            radius: 8
            border.color: root.errorText.length > 0 ? "#ffcdd2" : "#adf0b9"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Text {
                    text: root.errorText.length > 0 ? "Error" : "Result"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: root.errorText.length > 0 ? "#cf222e" : "#116329"
                }

                Text {
                    text: root.errorText.length > 0 ? root.errorText
                            : (root.result.length > 0 ? root.result
                                                      : "Press a button above")
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: root.errorText.length > 0 ? "#cf222e" : "#1f2328"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // Push everything up
        Item { Layout.fillHeight: true }
    }

    // ── Helper functions ───────────────────────────────────────

    function callModule(method, args) {
        root.errorText = ""
        root.result = ""

        if (typeof logos === "undefined" || !logos.callModule) {
            root.errorText = "Logos bridge not available (run inside logos-app)"
            return
        }

        var res = logos.callModule("calc_module", method, args)
        root.result = String(res)
    }

    function callTwoOp(method, a, b) {
        if (a === "" || b === "") {
            root.errorText = "Enter values for both a and b"
            return
        }
        callModule(method, [parseInt(a), parseInt(b)])
    }

    function callOneOp(method, n) {
        if (n === "") {
            root.errorText = "Enter a value for n"
            return
        }
        callModule(method, [parseInt(n)])
    }

    function callNoArg(method) {
        callModule(method, [])
    }
}
