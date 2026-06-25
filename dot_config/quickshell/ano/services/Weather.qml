pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning
import qs.modules.common
import qs.services

/**
 * Weather service using wttr.in API with optional GPS positioning.
 * Provides temperature, humidity, wind, UV, sunrise/sunset, and more.
 */
Singleton {
    id: root
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    readonly property string timeFormat: Config.options.time.format
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: root.getData()
    onCityChanged: root.getData()
    onTimeFormatChanged: root.getData()

    property var location: ({ valid: false, lat: 0, lon: 0 })

    property var data: ({
        uv: 0, humidity: 0, sunrise: 0, sunset: 0,
        windDir: 0, wCode: 0, city: 0, wind: 0,
        precip: 0, visib: 0, press: 0, temp: 0,
        tempFeelsLike: 0, lastRefresh: 0,
    })

    function convertTo24Hour(time12h) {
        if (!time12h || !time12h.includes(' ')) return "00:00"
        const [time, modifier] = time12h.split(' ')
        let [hours, minutes] = time.split(':')
        if (hours === '12') hours = '00'
        if (modifier.toUpperCase() === 'PM') hours = parseInt(hours, 10) + 12
        return `${String(hours).padStart(2, '0')}:${minutes}`
    }

    function convertTo12HourLowercase(time12h) {
        if (!time12h || !time12h.includes(' ')) return "00:00"
        let [time, modifier] = time12h.split(' ')
        modifier = modifier.toUpperCase() === 'PM' ? 'pm' : 'am'
        return `${time} ${modifier}`
    }

    function refineData(raw) {
        let temp = {}
        temp.uv = raw?.current?.uvIndex || 0
        temp.humidity = (raw?.current?.humidity || 0) + "%"
        temp.windDir = raw?.current?.winddir16Point || "N"
        temp.wCode = raw?.current?.weatherCode || "113"
        temp.city = raw?.location?.areaName[0]?.value || "City"
        temp.temp = ""; temp.tempFeelsLike = ""

        if (root.timeFormat === "hh:mm") {
            temp.sunrise = convertTo24Hour(raw?.astronomy?.sunrise)
            temp.sunset = convertTo24Hour(raw?.astronomy?.sunset)
        } else if (root.timeFormat === "h:mm ap") {
            temp.sunrise = convertTo12HourLowercase(raw?.astronomy?.sunrise)
            temp.sunset = convertTo12HourLowercase(raw?.astronomy?.sunset)
        } else {
            temp.sunrise = raw?.astronomy?.sunrise
            temp.sunset = raw?.astronomy?.sunset
        }

        if (root.useUSCS) {
            temp.wind = (raw?.current?.windspeedMiles || 0) + " mph"
            temp.precip = (raw?.current?.precipInches || 0) + " in"
            temp.visib = (raw?.current?.visibilityMiles || 0) + " m"
            temp.press = (raw?.current?.pressureInches || 0) + " psi"
            temp.temp = (raw?.current?.temp_F || 0) + "°F"
            temp.tempFeelsLike = (raw?.current?.FeelsLikeF || 0) + "°F"
        } else {
            temp.wind = (raw?.current?.windspeedKmph || 0) + " km/h"
            temp.precip = (raw?.current?.precipMM || 0) + " mm"
            temp.visib = (raw?.current?.visibility || 0) + " km"
            temp.press = (raw?.current?.pressure || 0) + " hPa"
            temp.temp = (raw?.current?.temp_C || 0) + "°C"
            temp.tempFeelsLike = (raw?.current?.FeelsLikeC || 0) + "°C"
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date
        root.data = temp
    }

    function getData() {
        let command = "curl -s wttr.in"
        if (root.gpsActive && root.location.valid)
            command += `/${root.location.lat},${root.location.lon}`
        else
            command += `/${formatCityName(root.city)}`
        command += "?format=j1 | jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'"
        fetcher.command[2] = command
        fetcher.running = true
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+')
    }

    Component.onCompleted: {
        if (!root.gpsActive) return
        positionSource.start()
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return
                try {
                    root.refineData(JSON.parse(text))
                } catch (e) {
                    console.error(`[Weather] ${e.message}`)
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval
        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude
                root.location.lon = position.coordinate.longitude
                root.location.valid = true
                root.getData()
            } else {
                root.gpsActive = root.location.valid
                console.error("[Weather] Failed to get GPS location.")
            }
        }
        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop()
                root.location.valid = false
                root.gpsActive = false
                Quickshell.execDetached(["notify-send", "Weather Service",
                    "Cannot find a GPS service. Using fallback method.", "-a", "Ano Shell"])
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
