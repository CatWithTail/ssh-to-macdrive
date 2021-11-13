#!/usr/bin/env bash

#Config
sshConfigFile=~/.ssh/config
WorkFolder=~/my_server
RemoteDir=~/
sshname=myremoteserver

#Functions:
function helpme {
  echo "how to:"
  echo "keyfile - file with the ssh key"
  echo "workdir - directory, where we gonna mount the drive"
  echo "sshname - name of your part of ssh config. Like Host '$sshname'"
  echo "sshuser - user for ssh connection"
  echo "sshconfig - ssh config file. Devault value is ~/.ssh/config"
  echo "remotedir - directory on the remote server"
  echo "host - IP address or FQDN"
  echo "help - print the page"
  echo "Example:"
  echo "$0 keyfile=/tmp/secret.pem host=my.secret.server.ie remotedir=/tmp sshconfig=~/.ssh/config sshuser=secretuser"
  exit 0
}

function check_paremeters {
  if [ ! -z "$keyfile" ] || [ ! -z "$sshuser" ] ||[ ! -z "$sshHostName" ]
    then
      echo "some of mandatory parameters not added"
      echo "If the server already in ssh config - use the 'sshname=' "
      echo "if the server isn't known - use 'keyfile=', 'sshuser' and 'sshHostName'"
      helpme
      exit 1
  fi
}

function check_WorkFolder {
    if [ ! -d "$WorkFolder" ]
      then
        echo "mkdir $WorkFolder"
        echo "Created $WorkFolder"
      else
        echo "Process with $WorkFolder"
    fi
}

function modify_ssh_config {
    echo "Host $sshname" >> $sshConfigFile
    echo "  user $sshuser" >> $sshConfigFile
    echo "  HostName $sshHostName" >> $sshConfigFile
    echo "  IdentityFile $keyfile" >> $sshConfigFile
}

function check_keyfile {
  touch $sshConfigFile
  if (( $(cat $sshConfigFile | grep -c "$sshname") < 1 ))
    then
      check_paremeters
      modify_ssh_config
  fi
}

function check_sshfs {
    if [ ! $(command -v sshfs) ]
      then
        if [ ! $(command -v brew) ]
          then
            echo "Oh, no, you have no installed sshfs, osxfuse and Homebrew"
            echo "Installing brew:"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew cask install osxfuse && brew install sshfs
    fi
    echo "process with: "
    echo "sshfs -F $sshConfigFile $sshname:$RemoteDir $WorkFolder -ovolname=$sshname"
}

#ArgParse
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
    case "$KEY" in
            keyfile)          keyfile=${VALUE} ;;
            workdir)          WorkFolder=${VALUE} ;;
            sshname)          sshname=${VALUE} ;;
            sshuser)          sshuser=${VALUE} ;;
            sshconfig)        sshConfigFile=${VALUE} ;;
            remotedir)        RemoteDir=${VALUE} ;;
            host)             sshHostName=${VALUE} ;;
            help) helpme ;;
            *)
    esac
done

#Main:
check_WorkFolder
if [ ! -z "$keyfile" ]
  then
    echo "go with $keyfile"
    if [ ! -f "$keyfile" ]
      then
        echo "the keyfile does't exit"
        exit 1
    fi
  else
    check_keyfile
fi
check_sshfs
sshfs -F $sshConfigFile $sshname:$RemoteDir $WorkFolder -ovolname=$sshname
open $WorkFolder
