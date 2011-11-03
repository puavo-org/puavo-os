# -*- coding: utf-8 -*-

"""Run the tests with nose.

  $ sudo pip install nose
  $ nosetests

"""

# the application instance - one for all tests
from PySide import QtGui
QT_APP = QtGui.QApplication([])
__all__ = [
    "QT_APP"
]

