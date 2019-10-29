//
//  WindowWidget.cpp
//  interface/src/ui/WindowWidget
//
//  Created by Zach Fox on 2019-10-29.
//  Copyright 2019 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <QQuickView>

#include "Application.h"
#include "MainWindow.h"
#include "WindowWidget.h"

WindowWidget::WindowWidget(const QUrl& sourceUrl) {
    QQuickView view;
    view.setSource(sourceUrl);
    view.setParent(qApp->getPrimaryWindow()->findMainWindow());
    //view.setFlags();
    view.show();

    //QObject *object = view.rootObject();
}

WindowWidget::~WindowWidget() {
}
