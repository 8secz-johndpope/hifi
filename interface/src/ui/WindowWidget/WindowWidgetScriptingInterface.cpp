//
//  WindowWidgetScriptingInterface.cpp
//  interface/src/ui/WindowWidget
//
//  Created by Zach Fox on 2019-10-29.
//  Copyright 2019 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <QtCore/QThread>
#include <QtScript/QScriptEngine>

#include "shared/QtHelpers.h"
#include "WindowWidgetScriptingInterface.h"

WindowWidgetScriptingInterface::WindowWidgetScriptingInterface() {

}

WindowWidgetPointer WindowWidgetScriptingInterface::createWindowWidget(const QString& sourceUrlString) {
    QUrl sourceUrl = QUrl::fromLocalFile(sourceUrlString);

    if (QThread::currentThread() != thread()) {
        WindowWidgetPointer windowWidget = nullptr;
        BLOCKING_INVOKE_METHOD(this, "createWindowWidget",
            Q_RETURN_ARG(WindowWidgetPointer, windowWidget),
            Q_ARG(QString, sourceUrlString)
        );
        return windowWidget;
    }

    return new WindowWidget(sourceUrl);
}

QScriptValue windowWidgetPointerToScriptValue(QScriptEngine* engine, const WindowWidgetPointer& in) {
    return engine->newQObject(in, QScriptEngine::ScriptOwnership);
}

void windowWidgetPointerFromScriptValue(const QScriptValue& object, WindowWidgetPointer& out) {
    if (const auto windowWidget = qobject_cast<WindowWidgetPointer>(object.toQObject())) {
        out = windowWidget;
    }
}

void registerWindowWidgetMetaType(QScriptEngine* engine) {
    qScriptRegisterMetaType(engine, windowWidgetPointerToScriptValue, windowWidgetPointerFromScriptValue);
}