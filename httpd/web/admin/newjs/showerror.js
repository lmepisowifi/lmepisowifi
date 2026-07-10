(function($){

$.fn.bgiframe = ($.browser.msie && /msie 6\.0/i.test(navigator.userAgent) ? function(s) {
    s = $.extend({
        top     : 'auto', // auto == .currentStyle.borderTopWidth
        left    : 'auto', // auto == .currentStyle.borderLeftWidth
        width   : 'auto', // auto == offsetWidth
        height  : 'auto', // auto == offsetHeight
        opacity : true,
        src     : 'javascript:false;'
    }, s);
    var html = '<iframe class="bgiframe"frameborder="0"tabindex="-1"src="'+s.src+'"'+
                   'style="display:block;position:absolute;z-index:-1;'+
                       (s.opacity !== false?'filter:Alpha(Opacity=\'0\');':'')+
                       'top:'+(s.top=='auto'?'expression(((parseInt(this.parentNode.currentStyle.borderTopWidth)||0)*-1)+\'px\')':prop(s.top))+';'+
                       'left:'+(s.left=='auto'?'expression(((parseInt(this.parentNode.currentStyle.borderLeftWidth)||0)*-1)+\'px\')':prop(s.left))+';'+
                       'width:'+(s.width=='auto'?'expression(this.parentNode.offsetWidth+\'px\')':prop(s.width))+';'+
                       'height:'+(s.height=='auto'?'expression(this.parentNode.offsetHeight+\'px\')':prop(s.height))+';'+
                '"/>';
    return this.each(function() {
        if ( $(this).children('iframe.bgiframe').length === 0 )
            this.insertBefore( document.createElement(html), this.firstChild );
    });
} : function() { return this; });

// old alias
$.fn.bgIframe = $.fn.bgiframe;

function prop(n) {
    return n && n.constructor === Number ? n + 'px' : n;
}

})(jQuery);

function showAttentin(){
	$(".divinput").each(function(i){
		$(this).children().focusin(function() {   
		$(this.parentNode.parentNode).find(".msg").css("display","inline");	
		$(this.parentNode.parentNode).find("div[class=error]").css("display","none");		
     	});
	$(this).children().focusout(function() {
        $(this.parentNode.parentNode).find(".msg").css("display","none");
     });
	});
}

function showErrors(){
		var t = this;
		for ( var i = 0; this.errorList[i]; i++ ) {
			var error = this.errorList[i];
			this.settings.highlight && this.settings.highlight.call( this, error.element, this.settings.errorClass, this.settings.validClass );
			
			var elename = this.idOrName(error.element);
			if(this.settings.highlight){
					var el = $("input[name="+elename+"]");//针对复选框
			    for (var j = 0; j<el.length; j++)
			        this.settings.highlight.call(this, el[j], this.settings.errorClass, this.settings.validClass);
			
			}
			// 错误信息div
			var errdiv = $('div[htmlfor='+ elename + ']');
			var errimg = $('img[htmlfor='+ elename + ']');
			if(errdiv.length == 0){ // 没有div则创建

				errdiv = $('<div>' 
						/*+ '<img src="../files/left_icon.gif" width="6" height="27" align="absmiddle"  style="float:left;" />'*/
						+ '<p class="errmsgP errmsg">'
						+'</p>'
/*						+ '<img src="../files/right_icon.gif" width="6" height="27" align="absmiddle"  style="float:left;" />'
*/						+ '</div>');
				
				//errdiv.bgiframe();
				errdiv.attr({"for":  this.idOrName(error.element), generated: true});
				errdiv.addClass(this.settings.errorClass);
				if(elename=='portId')
					errdiv.css("width","100px");
				//errdiv.css({left : $.getLeft(error.element) + 'px',top : $.getTop(error.element) + 'px'}); // 显示在控件的下面
				errdiv.appendTo(error.element.parentNode.parentNode);
			}
/*			if(errimg.length == 0){ // 没有img则创建
				errimg = $('<img alt="错误" src="../images/unchecked.gif">')
				errimg.attr({"for":  this.idOrName(error.element), generated: true});
				errimg.appendTo(error.element.parentNode);
				//errimg.insertAfter(error.element);
			}*/
//			errimg.show();
			$(error.element.parentNode.parentNode).find(".msg").css("display","none");
			errdiv.show();
			errdiv.find(".errmsg").html(error.message || "");
//			alert(error.element.pageX);
		/*$('div[htmlfor="'+ elename+ '"]').css({left : ((error.element.pageX+20) + 'px',top : ((error.element.pageY+20) + 'px'}); */
																													// 显示在鼠标位置偏移20的位置
			// 鼠标放到图片显示错误
/*			$(errimg).hover(function(e){
				$('div[htmlfor="'+ $(this).attr('htmlfor') + '"]').css({left : (e.pageX+20) + 'px',top : (e.pageY+20) + 'px'}); // 显示在鼠标位置偏移20的位置
				$('div[htmlfor="'+ $(this).attr('htmlfor') + '"]').fadeIn(200);
			},
			function(){
				$('div[htmlfor="'+ $(this).attr('htmlfor') + '"]').fadeOut(200);
			});
			// 鼠标放到控件上显示错误
			var el = $("input[name="+elename+"]");//针对复选框
			for (var j = 0; j<el.length; j++){
			$(el).hover(function(e){
				$('div[htmlfor="'+ t.idOrName(this) + '"]').css({left : (e.pageX+20) + 'px',top : (e.pageY+20) + 'px'}); // 显示在鼠标位置偏移20的位置
				$('div[htmlfor="'+ t.idOrName(this) + '"]').fadeIn(200);
			},
			function(){
				$('div[htmlfor="'+ t.idOrName(this) + '"]').fadeOut(200);
			});
			}*/
		}
		
		// 校验成功的去掉错误提示
		for ( var i = 0; this.successList[i]; i++ ) {
			$('div[htmlfor="'+ this.idOrName(this.successList[i]) + '"]').remove();
			$('img[htmlfor=' + this.idOrName(this.successList[i]) + ']').hide();
			// 自定义高亮
			if (this.settings.unhighlight) {
		        var el = $("input[name=" + this.idOrName(this.successList[i]) + "]"); //针对复选框
		        for (var j = 0; j < el.length; j++)
		            this.settings.unhighlight.call(this, el[j], this.settings.errorClass, this.settings.validClass);
			}
		}
		
		if (this.settings.unhighlight) {
		    for (var i = 0, elements = this.validElements(); elements[i]; i++) {
				//针对复选框判段是否在errorList里面
				var isSelector = false;
				for(var k = 0; this.errorList[k]; k++ ){
					var elename = this.idOrName(this.errorList[k].element);
					if(this.idOrName(elements[i])==this.idOrName(this.errorList[k].element)){
					isSelector = true;	
					}
				}
				if(!isSelector){									
					$('div[htmlfor="'+ this.idOrName(elements[i]) + '"]').remove();
					$('img[htmlfor=' + this.idOrName(elements[i]) + ']').hide();
					this.settings.unhighlight.call(this, elements[i], this.settings.errorClass, this.settings.validClass);
				}
			}
		}
	}
	
jQuery.extend(jQuery.validator.messages, {
        required: "请输入信息",
		remote: "请修正该字段",
		email: "请输入正确格式的电子邮件",
		url: "请输入合法的网址",
		date: "请输入合法的日期",
		dateISO: "请输入合法的日期 (ISO).",
		number: "请输入合法的数字",
		digits: "只能输入整数",
		creditcard: "请输入合法的信用卡号",
		equalTo: "请再次输入相同的值",
		accept: "请输入拥有合法后缀名的字符串",
		maxlength: jQuery.validator.format("请输入一个长度最多是 {0} 的字符串"),
		minlength: jQuery.validator.format("请输入一个长度最少是 {0} 的字符串"),
		len: jQuery.validator.format("请输入一个长度是 {0} 的字符串"),
		rangelength: jQuery.validator.format("请输入长度介于{0}-{1}的字符串"),
		range: jQuery.validator.format("请输入{0}-{1}之间的值"),
		evenRange: jQuery.validator.format("请输入{0}-{1}之间的偶数"),
		max: jQuery.validator.format("请输入一个最大为 {0} 的值"),
		min: jQuery.validator.format("请输入一个最小为 {0} 的值")
});

jQuery.validator.addMethod("ip", function(value, element) {    
  return this.optional(element) || (/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/.test(value) && (RegExp.$1 <256 && RegExp.$2<256 && RegExp.$3<256 && RegExp.$4<256));    
}, "ip格式为192.168.22.255"); 

jQuery.validator.addMethod("mac", function(value, element) {    
  return this.optional(element) || (/^([\dA-Fa-f]{2}-){5}[\dA-Fa-f]{2}$/.test(value));    
}, "例：00-24-21-19-bD-E4"); 

jQuery.validator.addMethod("mac0f", function(value, element) {    
  return this.optional(element) || (value.toLowerCase() !="00-00-00-00-00-00"&&value.toLowerCase() !="ff-ff-ff-ff-ff-ff");    
}, "MAC地址不为全0或全f"); 

jQuery.validator.addMethod("len", function(value, element,param) {    
  return this.optional(element) || this.getLength($.trim(value), element) == param;    
}); 
jQuery.validator.addMethod("evenRange",	function( value, element, param ) {
			return this.optional(element) || ( value >= param[0] && value <= param[1] && value%2==0);
});
jQuery.validator.addMethod("subnetmask", function(value, element) {   
	var IPPatern = /^\d{1,3}\.\d{1,3}\.\d{1,3}$/;
	var isTrue=true;
	if(IPPatern.test(value))
		  return false;
	var IPArray=value.split(".");
	var ip1=parseInt(IPArray[0]);
	var ip2=parseInt(IPArray[1]);
	var ip3=parseInt(IPArray[2]);
	var ip4=parseInt(IPArray[3]);
	if(ip1<0||ip1>255||ip2<0||ip2>255||ip3<0||ip3>255||ip4<0||ip4>255)
		return false;
	var ip_binary=_checkIput_formatIp(ip1)+_checkIput_formatIp(ip2)+
	_checkIput_formatIp(ip3)+_checkIput_formatIp(ip4);
	if(-1!=ip_binary.indexOf("01"))
		return false;
	return true;   
}); 
function _checkIput_formatIp(ip){
	return (ip+256).toString(2).substring(1);
}