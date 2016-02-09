#!/usr/bin/env bash
set -e

# BootstrapShhhhhh
# ================
#
# Author: @rajiteh <rajiteh@gmail.com>
# License: MIT
#
# Installs a bunch of sh!.
#
# Usage [PACKAGE_VAR=value ... ] ./bootstrap.sh <package[=version] ... >
# Example $ APP_REPO_GIT="git@host:user/proj.git" ./bootstrap.sh nvm=0.12 rbenv app
#
# Packages: rbenv nvm apache2 php mysql pip app
#
# Package notes:
#   * app
#       - Package var APP_REPO_GIT, git URL of the repository.
#       - Package var APP_DEPLOY_KEY, private key with pull rights to the target
#         repository.
#       - APP_DEPLOY_KEY can be ignored if SSH agent forwarding is enabled.
#       - A file named 'Buildfile' will be executed after deployment if found
#         at the root of repository.
#

# Script vars
SHELL_RC="${HOME}/.bashrc"
INSTALL=(base $@ clean)
INDENT="--------->"
_action=""
export DEBIAN_FRONTEND=noninteractive


# Package vars: mysql
DBPASSWORD='vagrant'

function install_base() {
    _say "INSTALLING BASE DEPENDENCIES"
    _add_apt_repository multiverse

    _add_apt_repository -y ppa:git-core/ppa

    _update_apt

    _say "Setting locale."
    _package_install language-pack-en
    sudo locale-gen en_US.UTF-8 > /dev/null
    sudo dpkg-reconfigure locales > /dev/null

    _update_apt

    _fix_broken_dependencies

    _package_install autoconf build-essential git wget

    _say "END INSTALLING BASE DEPENDENCIES"
}

function install_clean() {
    _say "Cleaning up cache."
    sudo apt-get -qq -y autoclean
    sudo apt-get -qq -y clean
}

function install_rbenv() {
    local version="$1"
    [ -z "$1" ] &&  version="2.2.1"
    local gem_rc="${HOME}/.gemrc"
    local default_gems="bundler foreman"
    _say "Configuring for version ${version}"

    _package_install autoconf bison build-essential libssl-dev \
        libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev \
        libffi-dev libgdbm3 libgdbm-dev

    _say "Installing rbenv."
    curl -s https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash

    _say "Updating shell rc."
    _ensure_line_sourced 'export RBENV_ROOT="$HOME/.rbenv"'
    _ensure_line_sourced 'export PATH="$HOME/.rbenv/bin:$PATH"'
    _ensure_line_sourced 'eval "$(rbenv init -)"'

    _say "Updating gem rc."
    touch $gem_rc
    _ensure_line_present "gem: --no-rdoc --no-ri " "${gem_rc}"

    _say "Installing dependencies."
    rbenv bootstrap-ubuntu-12-04 > /dev/null

    _say "Installing ruby."
    rbenv install -s $version > /dev/null
    rbenv global $version
    rbenv rehash

    _say "Installing gems."
    gem install $default_gems
}

function install_nvm() {
    local version="$1"
    [ -z "$1" ] && version="0.12"

    local npm_version="2"
    local default_modules="gulp bower grunt-cli supervisor"
    _say "Configuring for node=v${version} npm=v${npm_version}"

    _say "Downloading NVM."
    curl -s https://raw.githubusercontent.com/creationix/nvm/v0.27.1/install.sh | bash

    _say "Updating shell rc."
    _ensure_line_sourced 'export NVM_DIR="$HOME/.nvm"'
    _ensure_line_sourced '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

    _say "Installing nodejs."
    nvm install $version > /dev/null
    nvm alias default $version
    nvm use $version

    _say 'Configuring NPM.'
    npm install -g npm@$npm_version

    _say 'Installing modules.'
    npm install -g $default_modules
}

function install_pip() {
    local workon_home="${HOME}/.virtualenvs"

    _say "Setting up easy_install."
    wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python

    _say "Setting up pip."
    sudo easy_install pip

    _say "Setting up virtualenv."
    sudo pip install virtualenv
    sudo pip install virtualenvwrapper

    mkdir -p $workon_home

    _say "Updating shell rc."
    _ensure_line_sourced "export WORKON_HOME=${workon_home}"
    _ensure_line_sourced "source /usr/local/bin/virtualenvwrapper.sh"
    _ensure_line_sourced "export PIP_VIRTUALENV_BASE=${workon_home}"

    _say "Cleaning up."
    rm -f ./setuptools*.zip
}

function install_mysql() {
    _required_var "${DBPASSWORD}"
    local dbPassword=$DBPASSWORD
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password '"$dbPassword"''
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '"$dbPassword"''
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password '"$dbPassword"''
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password '"$dbPassword"''
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password '"$dbPassword"''
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-user string root'
    _package_install mysql-server-5.5 phpmyadmin
    sudo mysql_install_db > /dev/null
}

function install_apache() {
    _package_install apache2-mpm-worker libapache2-mod-fastcgi \
        apache2-threaded-dev apache2-utils

    _say "Configuring modules."
    sudo a2dismod php5 mpm_prefork > /dev/null
    sudo a2enmod rewrite actions fastcgi alias mpm_worker > /dev/null

    _say "Enable AllowOverride All."
    sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
    sudo service apache2 restart
}

function install_php() {
    install_apache
    _package_install php5-fpm php5-cli libmcrypt-dev libssl-dev openssl

    _say "Installing modules."
    _package_install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap \
        php5-mcrypt php5-memcache php5-redis php5-mysql php5-sqlite

    _say 'Setting up config file.'
    sudo sh -c 'cat > /etc/apache2/conf-available/php5-fpm.conf << EOL
<IfModule mod_fastcgi.c>
    AddHandler php5-fcgi .php
    Action php5-fcgi /php5-fcgi
    Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
    FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -idle-timeout 900 -host 127.0.0.1:9000 -pass-header Authorization
    <Directory /usr/lib/cgi-bin>
            Options ExecCGI FollowSymLinks
            SetHandler fastcgi-script
            Require all granted
    </Directory>
</IfModule>
EOL'
    _say 'Touching cgi-bin.'
    sudo touch /usr/lib/cgi-bin/php5.fcgi
    sudo chown -R www-data:www-data /usr/lib/cgi-bin

    _say 'Enabling FPM via TCP.'
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

    _say 'Enabling error logging.'
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini

    _say 'Enabling modules.'
    sudo php5enmod mcrypt
    sudo a2enconf php5-fpm
    sudo service php5-fpm restart > /dev/null
    sudo service apache2 restart > /dev/null

    _say 'Installing composer.'
    curl -sS https://getcomposer.org/installer | php > /dev/null
    sudo mv composer.phar /usr/local/bin/composer  > /dev/null
}

function install_app() {
    local app_path="${HOME}/app"
    local build_file="Buildfile"
    _required_var "${APP_REPO_GIT}"

    _say "Deploying app."
    _git_deploy "${APP_REPO_GIT}" "${app_path}"

    cd $app_path

    if [ -f "${build_file}" ]
        then
        _say "Buildfile detected."
        chmod +x "${build_file}"
        eval "./${build_file}"
    else
        _say "No Buildfile found."
    fi

}

function _git_deploy() {
    local deploy_key_prv_path="${HOME}/.ssh/deploy_rsa"
    local git_update=0
    local app_repo="${1}"
    local app_path="${2}"
    local app_branch="master"

    if [ -n "${APP_DEPLOY_KEY}" ]
        then
        _say "Installing deploy key."
        echo "${APP_DEPLOY_KEY}" > $deploy_key_prv_path
        key_opts="-i ${deploy_key_prv_path}"
    fi

    export GIT_SSH_COMMAND="ssh ${key_opts} \
                             -o StrictHostKeyChecking=no \
                             -o UserKnownHostsFile=/dev/null"

    _say "Detecting repository state."
    mkdir -p $app_path
    cd $app_path
    [ -d ".git" ] && (git remote -v | grep "${app_repo}") && \
        git_update=1

    if [ "${git_update}" = "0" ]
        then
        _say "Resetting app folder."
        rm -rf "${app_path}/*"

        _say "Cloning app."
        git clone $APP_REPO_GIT .
    else
        _say "Updating app repo."
        git pull origin $app_branch
    fi

    git checkout $app_branch
}

function _required_var() {
    if [ -z "${1}" ]
        then
        _say "ERROR: Required variable not present."
        exit 1
    fi
}
function _say() {
    echo $INDENT $_action $@
}

function _add_apt_repository(){
    _say "Adding apt repository ${@}"
    sudo apt-add-repository $@ > /dev/null
}

function _update_apt(){
    _say "Updating apt"
    sudo apt-get -qq -y update > /dev/null
}

function _fix_broken_dependencies(){
    _say "Fixing broken dependencies"
    sudo apt-get -f install > /dev/null
}

function _package_install() {
    _say "Configuring ${@}."
    sudo apt-get -qq -y install $@ > /dev/null
}

function _ensure_line_sourced() {
    _ensure_line_present "${1}" "${SHELL_RC}"
    eval "${1}"
}

function _ensure_line_present() {
    local line="$1"
    local file="$2"

    if grep -Fxq "${line}" $file
    then
        _say "EXISTS: ${line}"
    else
        echo "${line}" >> $file
        _say " ADDED: ${line}"
    fi
}

_say "Following Packages will be installed ${INSTALL[@]}"

for pkg in "${INSTALL[@]}"
do
    IFS='=' read -ra pkg_ver <<< "${pkg}"
    _action="(${pkg_ver[0]})"
    eval "install_${pkg_ver[0]} ${pkg_ver[1]}"
done