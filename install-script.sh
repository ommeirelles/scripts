#!/usr/bin/env bash

declare -a PKGS=(
    "zsh"
    "openssh-server"
    "curl"
    "vim"
    "git"
)

HAVE_INSTALLED_ANY_PKG=0
for PKG in "${PKGS[@]}"; do
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PKG | grep "install ok installed")
    if [[ $PKG_OK == "install ok installed" ]]; then
        echo "$PKG is already installed"
        continue
    fi

    if [[ $PKG_OK != "install ok installed" ]]; then
        echo "Installing $PKG..."
        read -p "Press enter to continue"
        sudo apt install $PKG --yes
        HAVE_INSTALLED_ANY_PKG=1
    fi
done

sudo ufw allow ssh

sudo chsh -s $(which zsh)
if [[ $HAVE_INSTALLED_ANY_PKG == 1 ]]; then
    reboot
fi

if [[ $(zsh --version) == "command not found" ]]; then
    echo "ZSH is not installed"
    exit 1
fi

rm -f ~/.zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [[ ! $? -eq 0 ]]; then
    echo "Oh My Zsh installation failed"
    exit 1
fi

zsh

git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

cat ./.p10k.zsh >~/.p10k.zsh
cat ./.zshrc >~/.zshrc

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

if [[ ! $? -eq 0 ]]; then
    echo "NVM installation failed"
    exit 1
fi

nvm install --lts
npm install -g yarn

reboot

ssh-keygen -t ed25519 -C "ommeirelles@gmail.com"
