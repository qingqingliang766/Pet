#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "SystemController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 设置应用程序信息，以便 Qt.labs.settings 或 QtCore.Settings 可以保存数据到系统注册表/配置中
    app.setOrganizationName("MyPetCompany");
    app.setOrganizationDomain("mypet.com");
    app.setApplicationName("PetApp");

    SystemController sysCtrl;

    QQmlApplicationEngine engine;
    
    // 注册系统控制器到QML
    engine.rootContext()->setContextProperty("sysCtrl", &sysCtrl);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Pet", "Main");

    return app.exec();
}