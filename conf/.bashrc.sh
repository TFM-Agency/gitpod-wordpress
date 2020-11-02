
# WordPress Setup Script
export REPO_NAME=$(basename $GITPOD_REPO_ROOT)
export WP_INSTALL_PATH=${GITPOD_REPO_ROOT}/wp-install
export PROJECT_PATH=${WP_INSTALL_PATH}/wp-content/plugins/${REPO_NAME}

function wp-init-database () {
  # user     = wordpress
  # password = wordpress
  # database = wordpress
  mysql -e "CREATE DATABASE wordpress /*\!40100 DEFAULT CHARACTER SET utf8 */;"
  mysql -e "CREATE USER wordpress@localhost IDENTIFIED BY 'wordpress';"
  mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';"
  mysql -e "FLUSH PRIVILEGES;"
}

function wp-setup () {
  FLAG="$HOME/.wordpress-installed"

  # search the flag file
  if [ -f $FLAG ]; then
    echo 'WordPress already installed'
    return 1
  fi

  echo 'Please, wait ...'

  # this would cause mv below to match hidden files
  shopt -s dotglob
  
  # move the workspace temporarily
  # mkdir $HOME/workspace
  # mv ${GITPOD_REPO_ROOT}/* $HOME/workspace/
  
  # create a debugger launch.json
  mkdir -p ${GITPOD_REPO_ROOT}/.theia
  mv $HOME/gitpod-wordpress/conf/launch.json ${GITPOD_REPO_ROOT}/.theia/launch.json
  
  # create a database for this WordPress
  echo 'Creating MySQL user and database ...'
  wp-init-database 1> /dev/null
  
  

  # install WordPress
  echo 'Installing WordPress ...'
  rm -rf $WP_INSTALL_PATH
  mkdir -p $WP_INSTALL_PATH
  cd $WP_INSTALL_PATH
  wp core download
  cp $HOME/gitpod-wordpress/conf/wp-config.php ${WP_INSTALL_PATH}/wp-config.php
  wp core install \
    --url="$(gp url 8080 | sed -e s/https:\\/\\/// | sed -e s/\\///)" \
    --title="WordPress" \
    --admin_user="admin" \
    --admin_password="123" \
    --admin_email="admin@gitpod.test"
    
  echo 'Downloading Adminer ...'
  mkdir ${WP_INSTALL_PATH}/database/
  wget -q https://www.adminer.org/latest.php -O ${WP_INSTALL_PATH}/database/index.php
  
  echo 'Creating phpinfo() page ...'
  mkdir ${WP_INSTALL_PATH}/phpinfo/
  echo "<?php phpinfo(); ?>" > ${WP_INSTALL_PATH}/phpinfo/index.php

  # put the project files in the correct place
  # echo 'Creating project files ...'
  # PROJECT_PATH=${GITPOD_REPO_ROOT}/${APACHE_DOCROOT}/wp-content/$1/${REPO_NAME}
  # mkdir -p $PROJECT_PATH
  # mv $HOME/workspace/* ${PROJECT_PATH}
  # cd $DESTINATION

  # install project dependencies
  if [ -f composer.json ]; then
    echo 'Installing Composer packages ...'
    composer update 2> /dev/null
  fi
  
  if [ -f package.json ]; then
    echo 'Installing NPM packages ...'
    npm i 2> /dev/null
  fi

  if [ -f ${PROJECT_PATH}/.init.sh ]; then
    echo '.init.sh detected ...'
    cp ${PROJECT_PATH}/.init.sh ${WP_INSTALL_PATH}/.init.sh
    echo 'Running your .init.sh ...'
    cd ${WP_INSTALL_PATH}/
    /bin/bash ${WP_INSTALL_PATH}/.init.sh
    rm -rf ${WP_INSTALL_PATH}/.init.sh
  fi
  
  # finish
  shopt -u dotglob
  touch $FLAG
  
  echo 'Done!'
}

function wp-setup-theme () {
  wp-setup "themes"
}

function wp-setup-plugin () {
  wp-setup "plugins"
}

function wp-install-plugin () {
  echo 'Installing plugin in WordPress ...'
  mkdir -p $PROJECT_PATH
  cd ${GITPOD_REPO_ROOT}
  cp -r !(wp-install) ${PROJECT_PATH}
  cd $DESTINATION
}

function wp-update-gitignore () {
  echo "wp-install/" >> $GITPOD_REPO_ROOT/.gitignore
  echo "*.log" >> $GITPOD_REPO_ROOT/.gitignore
}

export -f wp-setup-theme
export -f wp-setup-plugin

# Helpers
function browse-url () {
  ENDPOINT=${1:-""}
  PORT=${2:-"8080"}
  URL=$(gp url $PORT | sed -e s/https:\\/\\/// | sed -e s/\\///)
  gp preview "${URL}${ENDPOINT}"
}

function browse-home () {
  browse-url "/"
}

function browse-wpadmin () {
  browse-url "/wp-admin"
}

function browse-dbadmin () {
  browse-url "/database"
}

function browse-phpinfo () {
  browse-url "/phpinfo"
}

function browse-emails () {
  browse-url "/" "8025"
}

export -f browse-url
export -f browse-home
export -f browse-wpadmin
export -f browse-dbadmin
export -f browse-phpinfo
export -f browse-emails

# use Node.js LTS
nvm use lts/* > /dev/null
export NODE_VERSION=$(node -v | sed 's/v//g')

# WP-CLI auto completion
. $HOME/wp-cli-completion.bash
