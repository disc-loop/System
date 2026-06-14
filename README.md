# System
An attempt to schematise my entire system.

# Tasks
- [x] Create Guix System installer with nonguix loaded
- [x] Install Guix System
    - Followed this: https://joshblais.com/blog/installing-non-guix/
- [x] Set up wifi
    - Had to pull in the system service and open KWalletManager (as I am using KDE Plasma and it uses that to store the Wifi secrets)
- [x] Configure channels and substitutes
    - The substitutes were especially important because Guix kept trying to build massive dependencies like gcc without them. These would take hours and sometimes fail, killing the whole build
- [x] Get browser
- [x] Set up bluetooth
    - Just needed to add the service
- [x] Install dev tools
- [ ] Get Ghostty from Nix
- [ ] Set up symlink farm (either Stow or Guix home)
- [ ] Pull in dotfiles
- [ ] Consolidate dotfiles with farm
- [ ] Get Steam
- [ ] Get better GPU drivers
