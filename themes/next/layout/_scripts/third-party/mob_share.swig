{% if theme.mob_share.enable %}
<script type="text/javascript">
    //微信二维码点击背景关闭
    $('body').delegate('.-mob-share-weixin-qrcode-bg','click', function(){
         $(".-mob-share-weixin-qrcode-close").trigger("click");
    }); 
</script>
{% endif %}

