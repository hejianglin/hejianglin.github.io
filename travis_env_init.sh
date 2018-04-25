#!/bin/bash

__COMMENTS__='
# OS: ubuntu 14.04 trusty
# nodejs: 6.9.1
# npm: 3.10.8
# sudo: required
# need "GIT_USER_NAME" "GIT_USER_EMAIL" "GIT_REPO_TOKEN" "GOOGLE_ANALYTICS" "DISQUS_SHORTNAME" variable in env.
# env variable "icarus_opacity_disable" to control icarus opacity version display enable or disable.
# how to use: in travis, use the script to run, eg:
#    source travis_env_init.sh
#    sh travis_env_init.sh
#    ./travis_env_init.sh
'


node --version
npm --version

echo "Hexo environment pre install start."
echo "${__COMMENTS__}"

npm i -g hexo-cli
npm i

echo "hexo and packages install complete."

# Set git config ,need set variable before
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
sed -i'' "s~git@github.com:~https://${GIT_REPO_TOKEN}@github.com/~" _config.yml

echo "Hexo environment pre install complete OK."