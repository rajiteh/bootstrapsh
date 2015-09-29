BootstrapShhhhhh
================

Author: @rajiteh <rajiteh@gmail.com>

License: MIT

## Description

Installs a bunch of sh!

## Usage

Syntax: `[PACKAGE_VAR=value ... ] ./bootstrap.sh <package[=version] ... >`

Example: `APP_REPO_GIT="git@host:user/proj.git" ./bootstrap.sh nvm=0.12 rbenv app`

### Packages:
- rbenv : Installs ruby via `rbenv`.
- nvm : Installs nodejs via `nvm`.
- apache2 : Installs Apache web server.
- php : Installs PHP-FPM and configures it for apache2.
- mysql : Installs mysql database server.
- pip : Installs pip and virtualenv for python development.
- app : Deploys and builds an application from a git repository.

## Package notes:
  * app
      - Package var `APP_REPO_GIT`, git URL of the repository.
      - Package var `APP_DEPLOY_KEY`, private key with pull rights to the target repository.
      - `APP_DEPLOY_KEY` can be ignored if SSH agent forwarding is enabled.
      - A file named `Buildfile` will be executed if found at the root of repository.


## Experimental Remote Deploy

### Configure

- Open `ssh_deploy.sh` and add the package vars between the marked lines.
```
...

## PACKAGE VARS START

export APP_DEPLOY_KEY="$(cat ssh_keys/deploy_rsa)"
export APP_REPO_GIT="git@server:user/project.git"

## PACKAGE VARS END

...

```

### Deploy

- Run `ssh_deploy.sh` with the arguments for the SSH command to login to target server.

#### Example: Vagrant

- You should have a vagrant VM running. (A Vagrantfile is supplied with this repository for convenience.)
- Create a git repository that is accessible to you via SSH agent forwarding or a deploy key.
- Ensure the package variables in `ssh_deploy.sh`
- Run ssh_deploy.sh
```
    $ ./ssh_deploy.sh -o StrictHostKeyChecking=no \
        -i .vagrant/machines/default/virtualbox/private_key \
        -p 2222 vagrant@localhost
```
