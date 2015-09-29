#!/bin/bash
cat bootstrap.sh | ssh $@ "cat > ~/bootstrap.sh"

ssh $@ 'bash -s' <<ENDSSH
chmod +x ~/bootstrap.sh

## PACKAGE VARS START

export APP_DEPLOY_KEY="$(cat ssh_keys/deploy_rsa)"
export APP_REPO_GIT=""

## PACKAGE VARS END

~/bootstrap.sh rbenv nvm app
ENDSSH