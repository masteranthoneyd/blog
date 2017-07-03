#!/bin/bash
hexo clean
hexo g
cp -r ./themes/next/source/static/js ./public/static/