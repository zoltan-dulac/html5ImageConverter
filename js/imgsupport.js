(function(document) {
    
    function setHTMLClass(height, className) {
        if (height == 2) {
            document.documentElement.className += ' ' + className;
        } else {
            document.documentElement.className += ' no-' + className;
        }
    }

    var JP2 = new Image();
    JP2.onload = JP2.onerror = function() {
        setHTMLClass(JP2.height, 'jpg2000');
    };
    JP2.src = 'data:image/jp2;base64,/0//UQAyAAAAAAABAAAAAgAAAAAAAAAAAAAABAAAAAQAAAAAAAAAAAAEBwEBBwEBBwEBBwEB/1IADAAAAAEAAAQEAAH/XAAEQED/ZAAlAAFDcmVhdGVkIGJ5IE9wZW5KUEVHIHZlcnNpb24gMi4wLjD/kAAKAAAAAABYAAH/UwAJAQAABAQAAf9dAAUBQED/UwAJAgAABAQAAf9dAAUCQED/UwAJAwAABAQAAf9dAAUDQED/k8+kEAGvz6QQAa/PpBABr994EAk//9k=';
})(window.sandboxApi && window.sandboxApi.parentWindow && window.sandboxApi.parentWindow.document || document);