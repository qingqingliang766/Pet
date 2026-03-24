#ifndef SYSTEMCONTROLLER_H
#define SYSTEMCONTROLLER_H

#include <QObject>
#include <QPoint>
#include <QString>

class SystemController : public QObject
{
    Q_OBJECT
public:
    explicit SystemController(QObject *parent = nullptr);

    // 将鼠标移动到指定屏幕坐标
    Q_INVOKABLE void moveMouseTo(int x, int y);
    
    // 模拟鼠标点击 (1: 左键, 2: 右键)
    Q_INVOKABLE void clickMouse(int button = 1);
    
    // 模拟键盘输入文字
    Q_INVOKABLE void typeText(const QString &text);

    // 获取当前鼠标位置
    Q_INVOKABLE QPoint getMousePosition();

    // 获取当前活动窗口的标题（用于屏幕雷达分析）
    Q_INVOKABLE QString getActiveWindowTitle();
};

#endif // SYSTEMCONTROLLER_H
