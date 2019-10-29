//
//  WindowWidget.h
//  interface/src/ui/WindowWidget
//
//  Created by Zach Fox on 2019-10-29.
//  Copyright 2019 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#pragma once
#ifndef hifi_WindowWidget_h
#define hifi_WindowWidget_h

#include <QObject>
#include <QtCore/QUrl>

class WindowWidget : public QObject {
    Q_OBJECT

public:
    WindowWidget(const QUrl& sourceUrl);
    ~WindowWidget();

//signals:

//public slots:

//private slots:

//private:
};

#endif // hifi_WindowWidget_h
