//
//  WindowWidgetScriptingInterface.h
//  interface/src/ui/WindowWidget
//
//  Created by Zach Fox on 2019-10-29.
//  Copyright 2019 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#pragma once
#ifndef hifi_WindowWidgetScriptingInterface_h
#define hifi_WindowWidgetScriptingInterface_h

#include <QString>
#include <QtCore/QMetaType>
#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtScript/QScriptValue>
#include <QQmlEngine>

#include <DependencyManager.h>

#include "WindowWidget.h"

typedef WindowWidget* WindowWidgetPointer;
QScriptValue windowWidgetPointerToScriptValue(QScriptEngine* engine, const WindowWidgetPointer& in);
void windowWidgetPointerFromScriptValue(const QScriptValue& object, WindowWidgetPointer& out);
void registerWindowWidgetMetaType(QScriptEngine* engine);
Q_DECLARE_METATYPE(WindowWidgetPointer)

class WindowWidgetScriptingInterface : public QObject, public Dependency {
    Q_OBJECT

public:
    WindowWidgetScriptingInterface();

    Q_INVOKABLE WindowWidgetPointer createWindowWidget(const QString& sourceUrlString);

//signals:

//public slots:

//private slots:

//private:
};

#endif // hifi_WindowWidgetScriptingInterface_h
