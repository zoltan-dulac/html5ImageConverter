var fullBleed = new function () {
  var me = this;
  
  
  me.init = function () {
    window.addEventListener('resize', resize);
    
    resize();
  }
  
  function resize(e) {
      
      var i,
          els = document.getElementsByClassName('full-bleed'),
          length = els.length;
      
      for (i=0; i<length; i++) {
          
          var el = els[i],
              initialWidth = getInitialWidth(el),
              parent = el.parentNode,
              parentWidth = parent.offsetWidth,
              scale = parentWidth/initialWidth;
          
          el.style.transformOrigin = '0 0';
          el.style.transform = 'scale(' + scale + ')';
          //el.style.width = width + 'px';
      }
  }
  
  function getInitialWidth(el) {
      var initWidth = el.getAttribute('data-fullbleed-initial-width');
      
      if (initWidth !== null) {
          return parseFloat(initWidth);
      } else {
          return el.offsetWidth;
      }
  }
  
  me.init();
}