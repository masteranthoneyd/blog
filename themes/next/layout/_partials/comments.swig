{% if page.comments %}
  <div class="comments" id="comments">
    {% if (theme.duoshuo and theme.duoshuo.shortname) or theme.duoshuo_shortname %}
      <div class="ds-thread" data-thread-key="{{ page.path }}"
           data-title="{{ page.title }}" data-url="{{ page.permalink }}">
      </div>
    {% elseif theme.facebook_sdk.enable and theme.facebook_comments_plugin.enable %}
      <div class="fb-comments"
           data-href="{{ page.permalink }}"
           data-numposts="{{ theme.facebook_comments_plugin.num_of_posts }}"
           data-width="{{ theme.facebook_comments_plugin.width }}"
           data-colorscheme="{{ theme.facebook_comments_plugin.scheme }}">
      </div>
    {% elseif theme.disqus_shortname %}
<div style="text-align:center;">
  <!-- <button class="btn" id="load-disqus" onclick="disqus.load();">加载 Disqus 评论</button> -->

</div>
      <div id="disqus_proxy_thread"></div>
      <div id="disqus_thread"></div>
      {% if theme.disqus_proxy.enable %}
          <script type="text/javascript">
              window.disqusProxy = {
                username: '{{ theme.disqus_proxy.username }}',
                server: '{{ theme.disqus_proxy.server }}',
                port: '{{ theme.disqus_proxy.port }}',
                defaultAvatar: '{{ theme.disqus_proxy.defaultAvatar }}',
                adminAvatar: '{{ theme.disqus_proxy.adminAvatar }}',
                identifier: '{{ page.path }}'
              };
              window.disqus_config = function () {
                this.page.url = '{{ page.permalink }}';
                this.page.identifier = '{{ page.path }}';
              };
              window.onload=function(){
                var s = document.createElement('script');
                s.src = "{{ theme.disqus_proxy.js }}";
                s.async = true;
                document.body.appendChild(s);
              }
          </script>
          <link rel="stylesheet" href="{{ theme.disqus_proxy.css }}">
      {% endif %}

    {% elseif theme.hypercomments_id %}
      <div id="hypercomments_widget"></div>
    {% elseif theme.gentie_productKey %}
      <div id="cloud-tie-wrapper" class="cloud-tie-wrapper"></div>
    {% elseif theme.youyan_uid %}
      <div id="uyan_frame"></div>
    {% endif %}
  </div>
{% endif %}
