import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtCore // 引入设置保存功能
import Qt.labs.platform as Platform // 引入系统托盘功能

Window {
    id: mainWindow
    width: 200
    height: 200
    visible: true
    title: qsTr("水蓝蓝 桌宠")
    color: "transparent"
    
    // 根据设置动态决定是否在任务栏显示图标
    flags: {
        var f = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint;
        if (!appSettings.showInTaskbar) {
            f |= Qt.Tool; // 添加 Qt.Tool 就会在主任务栏隐藏
        }
        return f;
    }

    // 宠物状态：idle（闲置）, moving（移动中）, acting（执行指令中）, chatting（聊天中）
    property string petState: "idle" 

    // 使用 Settings 持久化保存
    Settings {
        id: appSettings
        property string llmApiKey: ""
        property string llmApiUrl: "https://api.deepseek.com/v1/chat/completions"
        property string llmModelName: "deepseek-chat" // 新增模型名称配置
        property bool showInTaskbar: false // 默认不在主任务栏显示
        property bool radarEnabled: false // 默认关闭屏幕雷达
        property int radarInterval: 60 // 雷达扫描间隔(秒)，默认60秒
        property int bubbleDuration: 5 // 气泡显示时间(秒)，默认5秒
    }

    // 系统托盘图标（右下角）
    Platform.SystemTrayIcon {
        id: trayIcon
        visible: true
        icon.source: "qrc:/Pet/pet.png" 
        tooltip: "水蓝蓝 桌宠"

        menu: Platform.Menu {
            Platform.MenuItem {
                text: "显示/隐藏"
                onTriggered: mainWindow.visible = !mainWindow.visible
            }
            Platform.MenuItem {
                text: "💬 跟我聊天"
                onTriggered: chatWindow.show()
            }
            Platform.MenuItem {
                text: "⚙️ 设置 API"
                onTriggered: settingsWindow.show()
            }
            Platform.MenuItem {
                text: "📡 雷达设置"
                onTriggered: radarSettingsWindow.show()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: "❌ 退出游戏"
                onTriggered: Qt.quit()
            }
        }
    }

    // 将窗口初始化在屏幕右下角
    Component.onCompleted: {
        x = Screen.desktopAvailableWidth - width - 50
        y = Screen.desktopAvailableHeight - height - 50
    }

    // 宠物本体图片
    Image {
        id: petImage
        anchors.fill: parent
        source: "pet.png" 
        fillMode: Image.PreserveAspectFit

        // 鼠标拖拽与点击功能
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point startPos
            property bool isDragging: false

            onPressed: function(mouse) {
                startPos = Qt.point(mouse.x, mouse.y)
                isDragging = false
            }

            onPositionChanged: function(mouse) {
                if (mouse.buttons & Qt.LeftButton) {
                    if (Math.abs(mouse.x - startPos.x) > 3 || Math.abs(mouse.y - startPos.y) > 3) {
                        isDragging = true
                        var deltaX = mouse.x - startPos.x
                        var deltaY = mouse.y - startPos.y
                        mainWindow.x += deltaX
                        mainWindow.y += deltaY
                    }
                }
            }

            onReleased: function(mouse) {
                if (!isDragging) {
                    if (mouse.button === Qt.LeftButton) {
                        // 如果菜单正开着，点击左键就只是关闭菜单，不触发聊天
                        if (contextMenu.opened) {
                            contextMenu.close();
                            return;
                        }
                        if (petState === "idle") {
                            showChatBubble("你好呀！左键可以跟我互动，右键打开菜单哦~");
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        contextMenu.popup()
                    }
                }
            }
        }
    }

    // 右键菜单
    Menu {
        id: contextMenu
        
        // 当菜单关闭时确保状态同步
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        // 关键：当主窗口失去焦点时，强制关闭菜单（这是解决 Windows 无边框窗口菜单不消失的终极办法）
        Connections {
            target: mainWindow
            function onActiveChanged() {
                if (!mainWindow.active && contextMenu.opened) {
                    contextMenu.close();
                }
            }
        }

        MenuItem { 
            text: "💬 跟我聊天"
            onTriggered: chatWindow.show()
        }
        MenuItem { 
            text: "⚙️ 设置 API"
            onTriggered: settingsWindow.show()
        }
        MenuItem { 
            text: "📡 雷达设置"
            onTriggered: radarSettingsWindow.show()
        }
        MenuItem {
            // 独立的任务栏显示切换
            text: appSettings.showInTaskbar ? "🔲 隐藏任务栏图标" : "🔳 显示在任务栏"
            onTriggered: {
                appSettings.showInTaskbar = !appSettings.showInTaskbar
                mainWindow.hide()
                mainWindow.show()
            }
        }
        MenuSeparator {}
        MenuItem { 
            text: "❌ 退出游戏"
            onTriggered: Qt.quit()
        }
    }

    Popup {
        id: chatBubblePopup
        x: (mainWindow.width - width) / 2
        y: -height - 10 
        width: 180
        height: chatText.implicitHeight + 20
        padding: 0
        margins: 0
        closePolicy: Popup.NoAutoClose
        
        background: Rectangle {
            radius: 10
            color: "#f0f8ff"
            border.color: "#88ccff"
            border.width: 2
            opacity: 0.9
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                chatBubblePopup.close();
                chatWindow.show();
            }
        }

        Text {
            id: chatText
            anchors.fill: parent
            anchors.margins: 10
            wrapMode: Text.Wrap
            text: ""
            font.pixelSize: 14
            color: "#333333"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Timer {
            id: chatTimer
            interval: appSettings.bubbleDuration * 1000 
            onTriggered: chatBubblePopup.close()
        }
    }

    ListModel {
        id: chatHistoryModel
    }

    function addHistory(role, content) {
        var timeStr = new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss");
        chatHistoryModel.append({"time": timeStr, "role": role, "content": content});
        if (chatHistoryModel.count > 50) {
            chatHistoryModel.remove(0);
        }
    }

    function showChatBubble(msg) {
        chatText.text = msg;
        chatBubblePopup.open();
        chatTimer.restart();
    }

    // 屏幕雷达定时器
    Timer {
        id: radarTimer
        interval: appSettings.radarInterval * 1000 
        running: appSettings.radarEnabled
        repeat: true
        onTriggered: {
            if (petState === "idle" && typeof sysCtrl !== "undefined") {
                var title = sysCtrl.getActiveWindowTitle();
                console.log("Radar Scan Triggered. Current Active Window:", title); 
                
                if (title !== "" && title.indexOf("水蓝蓝") === -1 && title.indexOf("PetApp") === -1 && title.indexOf("WorkerW") === -1 && title.indexOf("Program Manager") === -1) {
                    radarAnalyze(title);
                } else {
                    console.log("Radar Ignored this window (Self, Desktop, or Empty).");
                }
            } else {
                console.log("Radar Skipped. Pet is not idle or sysCtrl is undefined.");
            }
        }
    }

    function radarAnalyze(windowTitle) {
        if (!appSettings.llmApiKey) return;
        var xhr = new XMLHttpRequest();
        xhr.open("POST", appSettings.llmApiUrl);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Authorization", "Bearer " + appSettings.llmApiKey);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.choices && response.choices.length > 0) {
                        var msgObj = response.choices[0].message;
                        var reply = msgObj.content;
                        if (!reply || reply.trim() === "") {
                            reply = msgObj.reasoning_content || "（观察中...）";
                        }
                        showChatBubble("【观察中...】\n" + reply + "\n(点击找我聊天)");
                    }
                } catch(e) {}
            }
        }
        var body = JSON.stringify({
            "model": appSettings.llmModelName,
            "messages": [
                {"role": "system", "content": "你是一只叫水蓝蓝的可爱桌宠，陪伴在主人屏幕右下角。"},
                {"role": "user", "content": "主人当前正在看这个窗口/软件：【" + windowTitle + "】。请你结合这个软件名称，给出一句简短可爱的关心、吐槽或建议（不要超过15个字）。"}
            ],
            "temperature": 0.7
        });
        xhr.send(body);
    }

    Timer {
        id: idleTimer
        interval: 5000 
        running: true
        repeat: true
        onTriggered: {
            if (petState === "idle") {
                if (Math.random() < 0.3) {
                    moveToRandomPosition();
                }
            }
        }
    }

    NumberAnimation { id: moveAnimX; target: mainWindow; property: "x"; duration: 2000; easing.type: Easing.InOutQuad }
    NumberAnimation { id: moveAnimY; target: mainWindow; property: "y"; duration: 2000; easing.type: Easing.InOutQuad; onStopped: { if (petState === "moving") petState = "idle"; } }

    function moveToRandomPosition() {
        petState = "moving";
        let minX = 0;
        let maxX = Screen.desktopAvailableWidth - mainWindow.width;
        let minY = 0;
        let maxY = Screen.desktopAvailableHeight - mainWindow.height;
        moveAnimX.to = minX + Math.random() * (maxX - minX);
        moveAnimY.to = minY + Math.random() * (maxY - minY);
        moveAnimX.start();
        moveAnimY.start();
    }

    function controlComputerTo(targetX, targetY, clickType, typeString) {
        petState = "acting";
        let destX = targetX - mainWindow.width / 2;
        let destY = targetY - mainWindow.height / 2;
        destX = Math.max(0, Math.min(destX, Screen.desktopAvailableWidth - mainWindow.width));
        destY = Math.max(0, Math.min(destY, Screen.desktopAvailableHeight - mainWindow.height));
        moveAnimX.to = destX;
        moveAnimY.to = destY;
        moveAnimX.start();
        moveAnimY.start();
        
        var delayTimer = Qt.createQmlObject("import QtQuick; Timer {}", mainWindow);
        delayTimer.interval = 2100;
        delayTimer.repeat = false;
        delayTimer.triggered.connect(function() {
            if (typeof sysCtrl !== "undefined") {
                sysCtrl.moveMouseTo(targetX, targetY);
                if (clickType !== 0) sysCtrl.clickMouse(clickType);
                if (typeString && typeString !== "") sysCtrl.typeText(typeString);
            }
            petState = "idle";
            delayTimer.destroy();
        });
        delayTimer.start();
    }

    // 1. 聊天窗口
    Window {
        id: chatWindow
        width: 350
        height: 120
        title: "与水蓝蓝聊天"
        flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint 
        color: "#ffffff"
        
        // 当失去焦点（点击屏幕其他地方）时，自动隐藏聊天框
        onActiveChanged: {
            if (!active) {
                hide();
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: "#88ccff"
            border.width: 2
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                Row {
                    width: parent.width
                    Text { 
                        text: "和水蓝蓝说点什么吧~"
                        color: "#666"
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { Layout.fillWidth: true } 
                    Button {
                        text: "×"
                        width: 30
                        height: 30
                        background: Rectangle { color: "transparent" }
                        onClicked: chatWindow.hide()
                    }
                }

                TextField {
                    id: userInput
                    width: parent.width
                    placeholderText: "输入内容按回车发送..."
                    onAccepted: sendBtn.clicked()
                    
                    Component.onCompleted: {
                        chatWindow.onVisibleChanged.connect(function() {
                            if (chatWindow.visible) {
                                userInput.forceActiveFocus();
                            }
                        });
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 10
                    
                    Button {
                        text: "📜 历史记录"
                        onClicked: {
                            chatWindow.hide();
                            historyWindow.show();
                        }
                    }
                    
                    Button {
                        id: sendBtn
                        text: "发送"
                        onClicked: {
                            if (userInput.text !== "") {
                                let msg = userInput.text;
                                userInput.text = "";
                                chatWindow.hide();
                                
                                addHistory("我", msg); 
                                
                                showChatBubble("思考中...");
                                petState = "chatting";

                                var xhr = new XMLHttpRequest();
                                xhr.open("POST", appSettings.llmApiUrl);
                                xhr.setRequestHeader("Content-Type", "application/json");
                                xhr.setRequestHeader("Authorization", "Bearer " + appSettings.llmApiKey);

                                xhr.onreadystatechange = function() {
                                    if (xhr.readyState === XMLHttpRequest.DONE) {
                                        petState = "idle";
                                        console.log("API Response Status:", xhr.status);
                                        console.log("API Response Text:", xhr.responseText);
                                        
                                        if (xhr.status === 200) {
                                            try {
                                                var response = JSON.parse(xhr.responseText);
                                                if (response.choices && response.choices.length > 0) {
                                                    var msgObj = response.choices[0].message;
                                                    var reply = msgObj.content;
                                                    if (!reply || reply.trim() === "") {
                                                        reply = msgObj.reasoning_content || "（水蓝蓝发呆中...）";
                                                    }
                                                    showChatBubble(reply);
                                                    addHistory("水蓝蓝", reply); 
                                                } else {
                                                    showChatBubble("API返回了未知格式的数据。");
                                                }
                                            } catch(e) {
                                                showChatBubble("解析大模型回复失败！\n" + e);
                                            }
                                        } else {
                                            showChatBubble("网络错误或API配置有误: " + xhr.status + "\n请检查API Key和URL。");
                                        }
                                    }
                                }

                                var apiMessages = [
                                    {"role": "system", "content": "你是一只叫水蓝蓝的可爱桌宠，请用简短、活泼的语气回复主人的话。字数尽量控制在20字以内。"}
                                ];
                                
                                // 提取最近的10条历史记录发送给模型
                                var historyCount = chatHistoryModel.count;
                                var startIndex = Math.max(0, historyCount - 10);
                                for (var i = startIndex; i < historyCount; i++) {
                                    var item = chatHistoryModel.get(i);
                                    // 因为我们刚刚把当前用户消息加进去了，所以这里包含了用户的最新输入
                                    apiMessages.push({
                                        "role": item.role === "我" ? "user" : "assistant",
                                        "content": item.content
                                    });
                                }

                                var body = JSON.stringify({
                                    "model": appSettings.llmModelName, 
                                    "messages": apiMessages,
                                    "temperature": 0.7
                                });
                                xhr.send(body);
                            }
                        }
                    }
                }
            }
        }
    }

    // 2. 设置窗口
    Window {
        id: settingsWindow
        width: 400
        height: 420
        title: "设置"
        flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        color: "#ffffff"
        
        onActiveChanged: {
            if (!active) {
                hide();
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: "#88ccff"
            border.width: 2
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Row {
                    width: parent.width
                    Text { text: "大模型 API 配置"; font.bold: true; font.pixelSize: 16 }
                    Item { Layout.fillWidth: true } 
                    Button {
                        text: "×"
                        width: 30
                        height: 30
                        background: Rectangle { color: "transparent" }
                        onClicked: settingsWindow.hide()
                    }
                }

            ComboBox {
                id: providerCombo
                width: parent.width
                model: ["DeepSeek", "智谱 (Zhipu)", "豆包 (Doubao)", "自定义"]
                onActivated: function(index) {
                    if (index === 0) {
                        urlInput.text = "https://api.deepseek.com/v1/chat/completions";
                        modelInput.text = "deepseek-chat";
                    } else if (index === 1) {
                        urlInput.text = "https://open.bigmodel.cn/api/paas/v4/chat/completions";
                        modelInput.text = "glm-4";
                    } else if (index === 2) {
                        urlInput.text = "https://ark.cn-beijing.volces.com/api/v3/chat/completions";
                        modelInput.text = "ep-xxxxxx"; 
                    }
                }
                Component.onCompleted: {
                    currentIndex = -1 
                }
            }

            TextField {
                id: urlInput
                width: parent.width
                placeholderText: "API URL (如 https://...)"
                text: appSettings.llmApiUrl
            }

            TextField {
                id: modelInput
                width: parent.width
                placeholderText: "模型名称 (如 deepseek-chat 或 ep-...)"
                text: appSettings.llmModelName
            }

            TextField {
                id: keyInput
                width: parent.width
                placeholderText: "API Key (如 sk-...)"
                text: appSettings.llmApiKey
                echoMode: TextInput.Password
            }

            Row {
                spacing: 10
                Text { 
                    text: "气泡显示(秒):" 
                    anchors.verticalCenter: parent.verticalCenter
                }
                SpinBox {
                    id: bubbleSpin
                    from: 2
                    to: 60
                    value: appSettings.bubbleDuration
                    editable: true
                    width: 100
                }
            }

            Item { height: 10; width: 1 } 

            Row {
                anchors.right: parent.right
                spacing: 10
                Button {
                    text: "取消"
                    onClicked: settingsWindow.hide()
                }
                Button {
                    text: "保存"
                    onClicked: {
                        appSettings.llmApiUrl = urlInput.text;
                        appSettings.llmModelName = modelInput.text;
                        appSettings.llmApiKey = keyInput.text;
                        appSettings.bubbleDuration = bubbleSpin.value;
                        
                        settingsWindow.hide();
                        showChatBubble("API设置已保存！");
                    }
                }
            }
        }
    }

    // 3. 雷达独立设置窗口
    Window {
        id: radarSettingsWindow
        width: 350
        height: 200
        title: "屏幕雷达设置"
        flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        color: "#ffffff"
        
        onActiveChanged: {
            if (!active) {
                hide();
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: "#88ccff"
            border.width: 2
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Row {
                    width: parent.width
                    Text { text: "雷达功能配置"; font.bold: true; font.pixelSize: 16 }
                    Item { Layout.fillWidth: true } 
                    Button {
                        text: "×"
                        width: 30
                        height: 30
                        background: Rectangle { color: "transparent" }
                        onClicked: radarSettingsWindow.hide()
                    }
                }

                CheckBox {
                    id: radarCheck
                    text: "开启屏幕雷达 (定时分析当前窗口并互动)"
                    checked: appSettings.radarEnabled
                }

                Row {
                    spacing: 10
                    Text { 
                        text: "扫描间隔(秒):" 
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    SpinBox {
                        id: intervalSpin
                        from: 10
                        to: 3600
                        value: appSettings.radarInterval
                        editable: true
                        width: 100
                    }
                }

                Item { height: 5; width: 1 } 

                Row {
                    anchors.right: parent.right
                    spacing: 10
                    Button {
                        text: "取消"
                        onClicked: radarSettingsWindow.hide()
                    }
                    Button {
                        text: "保存"
                        onClicked: {
                            appSettings.radarEnabled = radarCheck.checked;
                            appSettings.radarInterval = intervalSpin.value;
                            
                            radarSettingsWindow.hide();
                            if (radarCheck.checked) {
                                showChatBubble("雷达已开启！\n每 " + intervalSpin.value + " 秒我会看看你在干嘛~");
                            } else {
                                showChatBubble("雷达已关闭，我乖乖待着啦~");
                            }
                        }
                    }
                }
            }
        }
    }

    // 4. 历史记录窗口
    Window {
        id: historyWindow
        width: 400
        height: 500
        title: "聊天历史记录"
        color: "#f5f5f5"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            
            Text {
                text: "与水蓝蓝的聊天记录"
                font.bold: true
                font.pixelSize: 16
            }
            
            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: chatHistoryModel
                clip: true
                spacing: 8
                
                delegate: Rectangle {
                    width: historyList.width
                    height: contentCol.height + 20
                    color: model.role === "我" ? "#e3f2fd" : "#ffffff"
                    radius: 8
                    border.color: "#bbdefb"
                    border.width: 1
                    
                    Column {
                        id: contentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 4
                        
                        Text {
                            text: model.role + " <font color='#888'>(" + model.time + ")</font>"
                            textFormat: Text.RichText
                            font.bold: true
                            font.pixelSize: 12
                            color: model.role === "我" ? "#1976d2" : "#00796b"
                        }
                        
                        Text {
                            text: model.content
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: 14
                        }
                    }
                }
                
                onCountChanged: {
                    historyList.positionViewAtEnd()
                }
            }
            
            Button {
                text: "关闭"
                Layout.alignment: Qt.AlignRight
                onClicked: historyWindow.hide()
            }
        }
    }
}
}
