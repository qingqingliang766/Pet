#include "SystemController.h"
#include <QCursor>
#include <QGuiApplication>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

SystemController::SystemController(QObject *parent) : QObject(parent)
{
}

void SystemController::moveMouseTo(int x, int y)
{
    QCursor::setPos(x, y);
}

void SystemController::clickMouse(int button)
{
#ifdef Q_OS_WIN
    DWORD flags = 0;
    if (button == 1) { // Left click
        flags = MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP;
    } else if (button == 2) { // Right click
        flags = MOUSEEVENTF_RIGHTDOWN | MOUSEEVENTF_RIGHTUP;
    }
    
    if (flags != 0) {
        INPUT input = {0};
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = flags;
        SendInput(1, &input, sizeof(INPUT));
    }
#endif
}

void SystemController::typeText(const QString &text)
{
#ifdef Q_OS_WIN
    for (int i = 0; i < text.length(); ++i) {
        QChar ch = text.at(i);
        
        INPUT inputs[2] = {0};
        
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wScan = ch.unicode();
        inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;
        
        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wScan = ch.unicode();
        inputs[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        
        SendInput(2, inputs, sizeof(INPUT));
    }
#endif
}

QPoint SystemController::getMousePosition()
{
    return QCursor::pos();
}

QString SystemController::getActiveWindowTitle()
{
#ifdef Q_OS_WIN
    HWND hwnd = GetForegroundWindow();
    if (hwnd) {
        wchar_t windowTitle[512];
        GetWindowTextW(hwnd, windowTitle, sizeof(windowTitle)/sizeof(wchar_t));
        return QString::fromWCharArray(windowTitle);
    }
#endif
    return QString();
}
