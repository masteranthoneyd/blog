```
docker run -d --name disqus-proxy -p 5509:5509 \
-e API_SECRECT=SnHXSv8uCu7MMfvmADaB9g3QmdwhB0Hnlw4676hi3CgRkksoC4Ab57oSHwo2sVv2 \
-e SHORT_NAME=ookamiantd \
ycwalker/disqus-proxy-server 
```
