pragma Singleton

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Io

/**
 * Battery service using UPower. Provides charge state, health,
 * low/critical/suspend/full notifications, and automatic suspend.
 */
Singleton {
    id: root
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState === UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState === UPowerDeviceState.PendingCharge || chargeState === UPowerDeviceState.FullyCharged
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: Config.options.battery.automaticSuspend
    readonly property bool soundEnabled: Config.options.sounds.battery

    property bool isLow: available && (percentage <= Config.options.battery.low / 100)
    property bool isCritical: available && (percentage <= Config.options.battery.critical / 100)
    property bool isSuspending: available && (percentage <= Config.options.battery.suspend / 100)
    property bool isFull: available && (percentage >= Config.options.battery.full / 100)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging
    property bool isFullAndCharging: isFull && isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull

    property real health: {
        const devList = UPower.devices.values
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i]
            if (dev.isLaptopBattery && dev.healthSupported) {
                const h = dev.healthPercentage
                if (h === 0) return 0.01
                else if (h < 1) return h * 100
                else return h
            }
        }
        return 0
    }

    onIsLowAndNotChargingChanged: {
        if (!root.available || !isLowAndNotCharging) return
        Quickshell.execDetached(["notify-send", "Low battery", "Consider plugging in your device", "-u", "critical", "-a", "Ano Shell", "--hint=int:transient:1"])
        if (root.soundEnabled) Audio.playSystemSound("dialog-warning")
    }

    onIsCriticalAndNotChargingChanged: {
        if (!root.available || !isCriticalAndNotCharging) return
        Quickshell.execDetached(["notify-send", "Critically low battery",
            `Please charge! Automatic suspend at ${Config.options.battery.suspend}%`,
            "-u", "critical", "-a", "Ano Shell", "--hint=int:transient:1"])
        if (root.soundEnabled) Audio.playSystemSound("suspend-error")
    }

    onIsSuspendingAndNotChargingChanged: {
        if (root.available && isSuspendingAndNotCharging)
            Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"])
    }

    onIsFullAndChargingChanged: {
        if (!root.available || !isFullAndCharging) return
        Quickshell.execDetached(["notify-send", "Battery full", "Please unplug the charger", "-a", "Ano Shell", "--hint=int:transient:1"])
        if (root.soundEnabled) Audio.playSystemSound("complete")
    }

    onIsPluggedInChanged: {
        if (!root.available || !root.soundEnabled) return
        Audio.playSystemSound(isPluggedIn ? "power-plug" : "power-unplug")
    }
}
