import GObject from "gi://GObject";
export var SystemIndicatorOrderItem;
(function (SystemIndicatorOrderItem) {
    function match(a, b) {
        if (a.isSystem != b.isSystem
            || a.nonOrdered != b.nonOrdered
            || a.hide != b.hide)
            return false;
        if (a.nonOrdered)
            return true;
        if (a.isSystem)
            return a.gtypeName == b.gtypeName;
        return (a.constructorName == b.constructorName
            && a.friendlyName == b.friendlyName
            && a.gtypeName == b.gtypeName);
    }
    SystemIndicatorOrderItem.match = match;
    function indicatorMatch(item, indicator) {
        if (item.nonOrdered)
            return false;
        if (item.gtypeName && GObject.type_name_from_instance(indicator) != item.gtypeName)
            return false;
        if (item.constructorName && indicator.constructor.name != item.constructorName)
            return false;
        return true;
    }
    SystemIndicatorOrderItem.indicatorMatch = indicatorMatch;
    SystemIndicatorOrderItem.Default = {
        hide: false,
        constructorName: "",
        friendlyName: "",
        gtypeName: "",
    };
    function create(friendlyName) {
        return {
            ...SystemIndicatorOrderItem.Default,
            friendlyName,
        };
    }
    SystemIndicatorOrderItem.create = create;
})(SystemIndicatorOrderItem || (SystemIndicatorOrderItem = {}));
