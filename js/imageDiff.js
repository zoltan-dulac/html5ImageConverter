var imageDiff = new function () {
	var me = this;
	
	me.init = function () {
		me.$doDiff = $('#doDiff').on('click', doDiffClickEvent);
		me.$body = $('body');
		doDiffClickEvent();
	}
	
	function doDiffClickEvent() {
		
		if (me.$doDiff[0].checked) {
			me.$body.addClass('showDiff');
		} else {
			me.$body.removeClass('showDiff');
		}
	}
}

imageDiff.init();
