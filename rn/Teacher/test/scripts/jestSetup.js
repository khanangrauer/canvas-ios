/* @flow */
const { NativeModules } = require('react-native')

NativeModules.NativeAccessibility = {
  focusElement: jest.fn(),
}

NativeModules.NativeLogin = {
  logout: jest.fn(),
}

NativeModules.PushNotifications = {
  requestPermissions: jest.fn(),
  scheduleLocalNotification: jest.fn(),
}

jest.mock('NetInfo', () => ({
  addEventListener: jest.fn(),
  isConnected: {
    addEventListener: jest.fn(),
    fetch: () => Promise.resolve(true),
  },
}))

jest.mock('Animated', () => {
  const ActualAnimated = require.requireActual('Animated')
  return {
    ...ActualAnimated,
    timing: (value, config) => {
      return {
        start: (callback) => {
          callback && callback()
        },
      }
    },
  }
})

// Fixes network calls in tests env.
global.XMLHttpRequest = require('xhr2').XMLHttpRequest
import './../../src/common/global-style'

global.V02 = true
global.V03 = true
global.V04 = true
global.V05 = true
global.V06 = true
global.V07 = true
