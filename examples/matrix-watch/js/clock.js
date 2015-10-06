var clock = new function () {
    var me = this;
    
    me.tick = function () {
        var d = new Date().toUTCString().split(/ /g),
            t = d[4].split(/:/g);
            
        document.getElementById('time').innerHTML =
            t[0] + ':' + t[1] + ' <span id="secs">' + t[2] + '</span>';
            
        document.getElementById('date').innerHTML =
            d[2] + ' ' + d[1] + ',' + d[3];
    }
    
    setInterval(me.tick, 500);
}
