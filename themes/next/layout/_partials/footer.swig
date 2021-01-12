<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">Hosted by <a href="https://pages.coding.me" style="font-weight: bold">Coding Pages</a></span> | <span class="post-count">共{{ totalcount(site) }}字</span>
</div>

{% if theme.copyright %}
<!-- <div class="theme-info">
  {{ __('footer.powered', '') }}
</div> --!>

<div class="theme-info">
  <a target="_blank" href="https://beian.miit.gov.cn/" rel="nofollow" style="color:#555;">粤ICP备18135202号-1</a>
</div>


<div style="width:300px;margin:0 auto;">
  <a target="_blank" href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=44010602005896" style="display:inline-block;text-decoration:none;height:20px;line-height:20px;">
    <img src="https://cdn.yangbingdong.com/img/beian/beian.png" style="float:left;" />
    <p style="float:left;height:20px;line-height:20px;margin: 0px 0px 0px 5px; color:#555;">粤公网安备 44010602005896号</p></a>
</div>

{% endif %}
