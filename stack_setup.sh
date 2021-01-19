#!/bin/bash

wrong_input() {
    echo "Insert a valid option!"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    clear && clear
    $1
}

ssh_config() {
    key_file="${USER}_git"

    # Checks if the SSH key file already exists and creates it
    if [ -f ~/.ssh/${key_file} ]
        then
            echo "There is already a key named '${key_file}'!"
        else
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/${key_file}
    fi

    echo "Copy the key below and paste it into your GitHub profile within the path 'Settings > SSH and GPG keys > New SSH key'"
    echo ""
    echo ""
    cat ~/.ssh/${key_file}.pub
    echo ""
    echo ""
    read -n 1 -s -r -p "Press any key when you are done..."

    ssh_config_content="Host github.com
    User git
    IdentityFile ~/.ssh/${key_file}"

    ssh_config_file="~/.ssh/config"

    # Checks if SSH config file exists and adds SSH keys into it to allow GitHub host usage
    if ! [ -f $ssh_config_file ]; then
        echo "$ssh_config_content" | sudo tee $ssh_config_file 1>/dev/null
    elif ! grep -q "$ssh_config_content" $ssh_config_file; then
        echo "$ssh_config_content" >> $ssh_config_file
    fi

    # Checks if ssh-agent is not running
    if ! [ $(ps ax | grep [s]sh-agent | wc -l) -gt 0 ] ; then
        # Creates service file for ssh-agent service
        ssh_service_content='[Unit]
        Description=SSH key agent

        [Service]
        Type=simple
        Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
        ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

        [Install]
        WantedBy=default.target'

        ssh_agent_file="/etc/systemd/user/ssh-agent.service"
        
        if ! [ -f $ssh_agent_file ]; then
            echo "$ssh_service_content" | sudo tee $ssh_agent_file 1>/dev/null
        fi

        # Adds a default path to the SSH socket from ssh-agent
        if ! grep -q "SSH_AUTH_SOCK DEFAULT" ~/.bashrc; then
            echo 'export SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' >> ~/.bashrc
        fi
        
        # Activates and starts ssh-agent daemon service
        systemctl --user enable ssh-agent
        systemctl --user daemon-reload
        systemctl --user start ssh-agent
    fi

    # Adds SSH key to ssh-agent, enabling it to be used by the current user
    ssh-add ~/.ssh/${key_file}
    mainmenu
}

clone_repo() {
    REPO_PATH="$2"
    echo "Repository '$1' will be cloned into $2/$1"
    echo "Do you want to change the destination folder?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes )
                read -p "Type the root folder where '$1' will be installed, without trailling bar ('/'): " REPO_PATH;
                clone_repo $1 $REPO_PATH;;
            No )
                git clone git@github.com:$1.git $REPO_PATH/$1
                echo "Repository '$1' cloned into $REPO_PATH/$1"
                sleep 2s
                break;;
        esac
    done
    read -n 1 -s -r -p "Press any key to continue..."
    clear && clear
    mainmenu
}

repomenu () {
    clear && clear
    count=0
    REPOS=()

    echo "======================= GitHub Repositories ======================="
    echo "==================================================================="
    echo "Type the numeric option of the repository you want to clone:"
    echo ""
    while IFS= read -r repo || [ "$repo" ]
    do
        ((count++))
        REPOS[$count]=$repo
        echo "$count - $repo"
    done < ./repositories.config
    echo ""
    echo "b - back to main menu"
    echo "x - exit script"
    read -p "Option: " repomenuinput

    if [[ "$repomenuinput" =~ ^[0-9]+$ ]] && [ ${REPOS[$repomenuinput]} ]; then
        clone_repo ${REPOS[$repomenuinput]} "$HOME/repos"
    elif [ "$repomenuinput" = "V" ] || [ "$repomenuinput" = "v" ];then
        mainmenu
    elif [ "$repomenuinput" = "X" ] || [ "$repomenuinput" = "x" ];then
        exit
    else
        wrong_input repomenu
    fi
}


dbmenu () {
    clear && clear
    echo "====================== Database client apps ======================"
    echo "=================================================================="
    echo "Type the numeric option of the database client you want to install:"
    echo ""
    echo "1 - DataGrip"
    echo "2 - DBeaver"
    echo ""
    echo "b - back to main menu"
    echo "x - exit script"
    read -p "Option: " dbmenuinput

    if [ "$dbmenuinput" = "1" ]; then
        sudo snap install datagrip --classic
        echo "DataGrip has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$dbmenuinput" = "2" ]; then
        sudo snap install dbeaver-community
        echo "DBeaver has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$dbmenuinput" = "V" ] || [ "$dbmenuinput" = "v" ];then
        mainmenu
    elif [ "$dbmenuinput" = "X" ] || [ "$dbmenuinput" = "x" ];then
        exit
    else
        wrong_input dbmenu
    fi
}


txtmenu () {
    clear && clear
    echo "======================== Text/Code Editors ========================"
    echo "==================================================================="
    echo "Type the numeric option of the text/code editor you want to install:"
    echo ""
    echo "1 - VisualStudio Code"
    echo "2 - PyCharm"
    echo "3 - Atom"
    echo "4 - Sublime Text"
    echo ""
    echo "b - back to main menu"
    echo "x - exit script"
    read -p "Option: " txtmenuinput

    if [ "$txtmenuinput" = "1" ]; then
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
        sudo apt-get -qq update
        sudo apt-get -qq install code
        echo "VSCode has been installed successfully."
        mainmenu
    elif [ "$txtmenuinput" = "2" ]; then
        sudo snap install pycharm-community --classic
        echo "PyCharm has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$txtmenuinput" = "3" ]; then
        sudo apt-get -qq update
        sudo apt-get -qq install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add
        sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
        sudo apt-get -qq update
        sudo apt-get -qq install atom
        echo "Atom has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$txtmenuinput" = "4" ]; then
        sudo apt-get -qq update
        sudo apt-get -qq install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
        sudo add-apt-repository "deb https://download.sublimetext.com/ apt/stable/"
        sudo apt-get -qq update
        sudo apt-get -qq install sublime-text
        echo "Sublime Text has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$txtmenuinput" = "B" ] || [ "$txtmenuinput" = "b" ];then
        mainmenu
    elif [ "$txtmenuinput" = "X" ] || [ "$txtmenuinput" = "x" ];then
        exit
    else
        wrong_input txtmenu
    fi
}

mainmenu () {
    clear && clear
    echo "========================= Data Stack Setup ========================="
    echo "===================================================================="
    echo "Type 0 to create and configure a SSH key to access Git repositories"
    echo "Type 1 to select a GitHub repository from a list to clone..."
    echo "Type 2 to select a database client app to install..."
    echo "Type 3 to select a text/code editor to install..."
    echo "Type 4 to install Postman (a REST API client to test HTTP requests)"
    echo "Type 5 to install Terminator (a Linux enhanced terminal app)"
    echo "Type 6 to install SQL Power Architect"
    echo "Type 7 to install VPN FortiClient"
    echo "Type 8 to install Docker and Docker Compose"
    echo "Type x to exit script"
    read -p "Option: " mainmenuinput

    if [ "$mainmenuinput" = "0" ]; then
        ssh_config
    elif [ "$mainmenuinput" = "1" ]; then
        repomenu
    elif [ "$mainmenuinput" = "2" ]; then
        dbmenu
    elif [ "$mainmenuinput" = "3" ]; then
        txtmenu
    elif [ "$mainmenuinput" = "4" ]; then
        sudo snap install postman
        echo "Postman has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$mainmenuinput" = "5" ]; then
        sudo apt-get -qq install terminator
        echo "Terminator has been installed successfully."
        sleep 3s
        mainmenu
    elif [ "$mainmenuinput" = "6" ]; then
        wget -P ~/Downloads 'http://www.bestofbi.com/downloads/architect/1.0.8/SQL-Power-Architect-generic-jdbc-1.0.8.tar.gz'
        mkdir -p ~/.sqlpwrarchitect
        tar xzf ~/Downloads/SQL-Power-Architect-generic-jdbc-1.0.8.tar.gz -C ~/.sqlpwrarchitect
        if ! grep -q "architect.jar" ~/.bash_aliases; then
            echo 'alias sqlarc="java -Xmx600M -jar ~/.sqlpwrarchitect/architect*/architect.jar"' >> ~/.bash_aliases
        fi
        rm ~/Downloads/SQL-Power-Architect-generic-jdbc-1.0.8.tar.gz
        read -n 1 -s -r -p "SQL Power Architect has been installed successfully. To start it, execute the command 'sqlarc'..."
        mainmenu
    elif [ "$mainmenuinput" = "7" ]; then
        sudo apt-get -qq install libgnome-keyring-dev libcanberra-gtk-module libcanberra-gtk3-module
        wget -P ~/Downloads 'https://fortinet-public.s3.cn-north-1.amazonaws.com.cn/FortiClient_Download/SSL-VPN-Linux_System_small_ssl_vpn_client/forticlientsslvpn_linux_4.4.2336.tar.gz'
        mkdir -p ~/.forticlient
        tar xzf ~/Downloads/forticlientsslvpn_linux_4.4.2336.tar.gz -C ~/.forticlient
        if ! grep -q "forticlientsslvpn" ~/.bash_aliases; then
            echo 'alias vpn="~/.forticlient/forticlientsslvpn/64bit/forticlientsslvpn"' >> ~/.bash_aliases
        fi
        rm ~/Downloads/forticlientsslvpn_linux_4.4.2336.tar.gz
        read -n 1 -s -r -p "FortClient VPN has been installed successfully. To start it, execute the command 'vpn'..."
        mainmenu
    elif [ "$mainmenuinput" = "8" ]; then
        # Install Docker Engine - Community
        # https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-engine---community
        sudo apt-get -qq remove docker docker-engine docker.io containerd runc -y
        sudo apt-get -qq update
        sudo apt-get -qq install \
                     apt-transport-https \
                     ca-certificates \
                     curl \
                     gnupg-agent \
                     software-properties-common

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get -qq update
        sudo apt-get -qq install docker-ce docker-ce-cli containerd.io -y

        # Manage Docker as a non-root user
        # https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user
        sudo groupadd docker -f
        sudo usermod -aG docker $USER
        newgrp docker

        # Configure Docker to start on boot
        # https://docs.docker.com/install/linux/linux-postinstall/#configure-docker-to-start-on-boot
        sudo systemctl enable docker
        sudo systemctl start docker

        # Install Docker-compose
        # https://docs.docker.com/compose/install/#install-compose-on-linux-systems
        sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        read -n 1 -s -r -p "Docker has been installed successfully. Restart your system to apply the changes..."
        exit
    elif [ "$mainmenuinput" = "X" ] || [ "$mainmenuinput" = "x" ]; then
        clear && clear
        exit
    else
        wrong_input mainmenu
    fi
}

mainmenu
