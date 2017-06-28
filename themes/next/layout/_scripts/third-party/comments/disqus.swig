{% if not (theme.duoshuo and theme.duoshuo.shortname) and not theme.duoshuo_shortname %}

  {% if theme.disqus_shortname %}

    <script type="text/javascript">
      var disqus_shortname = '{{theme.disqus_shortname}}';
      var disqus_identifier = '{{ page.path }}';

      var disqus_title = "{{ page.title|addslashes }}";


      function run_disqus_script(disqus_script) {
        var dsq = document.createElement('script');
        dsq.type = 'text/javascript';
        dsq.async = true;
        dsq.src = '//' + disqus_shortname + '.disqus.com/' + disqus_script;
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
      }

      var disqus = {
        load : function disqus(){
          if(typeof DISQUS !== 'object') {
            (function () {
            var s = document.createElement('script'); s.async = true;
            s.type = 'text/javascript';
            s.src = '//' + disqus_shortname + '.disqus.com/embed.js';
            (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
            }());
            $('#load-disqus').html("评论加载中，请确保你有梯子，若评论长时间未加载则你可能翻墙失败...").fadeOut(9000); ///加载后移除按钮
          }
  }
}

    </script>
  {% endif %}
{% endif %}
