<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">Hosted by <a href="https://pages.coding.me" style="font-weight: bold">Coding Pages</a></span>
</div>

{% if theme.copyright %}
<div class="powered-by">
  {{ __('footer.powered', '') }}
</div>

<div class="theme-info">
  {{ __('footer.theme') }} -
ookamiAntD | <span class="post-count">共{{ totalcount(site) }}字</span>
</div>

{% endif %}
