pragma Singleton
import Quickshell

Singleton {
    id: root

    // Format date as relative time (e.g., "just now", "5 min ago", "2 hours ago")
    function timeAgo(date) {
        let now = new Date();
        let diff = Math.floor((now - date) / 1000); // seconds
        if (diff < 60) return "just now";
        if (diff < 3600) return Math.floor(diff / 60) + " min ago";
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
        if (diff < 604800) return Math.floor(diff / 86400) + "d ago";
        return date.toLocaleDateString();
    }

    // Get day name from date
    function dayName(date, short) {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        let name = days[date.getDay()];
        return short ? name.substring(0, 3) : name;
    }

    // Get month name from date
    function monthName(date, short) {
        let months = ["January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"];
        let name = months[date.getMonth()];
        return short ? name.substring(0, 3) : name;
    }

    // Format date as "Day, Month DD"
    function formatDate(date) {
        return dayName(date, true) + ", " + monthName(date, true) + " " + date.getDate();
    }

    // Format time as "HH:MM" (24h) or "h:MM AM/PM" (12h)
    function formatTime(date, use24h) {
        if (use24h === undefined) use24h = true;
        let h = date.getHours();
        let m = date.getMinutes();
        let mStr = m < 10 ? "0" + m : "" + m;
        if (use24h) {
            let hStr = h < 10 ? "0" + h : "" + h;
            return hStr + ":" + mStr;
        }
        let period = h >= 12 ? "PM" : "AM";
        h = h % 12;
        if (h === 0) h = 12;
        return h + ":" + mStr + " " + period;
    }

    // Check if two dates are the same day
    function isSameDay(date1, date2) {
        return date1.getFullYear() === date2.getFullYear() &&
               date1.getMonth() === date2.getMonth() &&
               date1.getDate() === date2.getDate();
    }

    // Check if date is today
    function isToday(date) {
        return isSameDay(date, new Date());
    }
}
