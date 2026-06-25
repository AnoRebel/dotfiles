pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool micActive: (Pipewire.links?.values ?? []).some(link =>
        !(link?.source?.isStream ?? true)
            && !(link?.source?.isSink ?? true)
            && (link?.target?.isStream ?? false)
    )

    property bool screenSharing: false
}
