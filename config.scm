(use-modules (gnu)
             (gnu home)
             (gnu home services)
             (gnu home services sound)
             (gnu home services desktop)
             (gnu packages version-control)
             (gnu packages commencement)
             (gnu packages golang)
             (gnu packages guile)
             (gnu packages sml)
             (gnu packages node)
             (gnu packages smalltalk)
             (gnu packages prolog)
             (gnu packages forth)
             (gnu packages vim)
             (gnu packages file)
             (gnu packages admin)
             (gnu packages package-management)
             (gnu packages ssh)
             (gnu packages xdisorg)
             (gnu packages shells)
             (gnu packages terminals)
             (gnu packages web)
             (gnu packages tmux)
             (gnu packages docker)
             (gnu packages ebook)
             (gnu packages libreoffice)
             (gnu packages kde-graphics)
             (gnu packages video)
             (gnu packages gl)
             (gnu services guix)
             ;; Disabling till I get a new GPU
             ;; (nonguix transformations)
             (nongnu packages game-client)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu packages mozilla)
             (nongnu packages productivity)
             (nongnu system linux-initrd)
             (saayix packages terminals))

(use-service-modules cups
                     desktop
                     networking
                     ssh
                     xorg
                     sddm
                     docker)

(define %my-home
  (home-environment
    (packages (append (list ghostty
                            zsh
                            tmux
                            neovim
                            fzf
                            jq
                            docker
                            gcc-toolchain
                            go
                            guile-3.0-latest
                            smlnj
                            node
                            smalltalk
                            gprolog
                            gforth
                            firefox
                            obsidian
                            calibre
                            libreoffice
                            krita
                            vlc
                            ;; Using normal steam till I get a new GPU
                            ;; steam-nvidia-580
                            steam
                            flatpak)))

    (services
     (append (list (service home-dbus-service-type)
                   (service home-pipewire-service-type)) %base-home-services))))

(define %my-os
  (operating-system
    (kernel linux)

    ;; Pulled this straight from nonguix to get wireless working. Might need to
    ;; come back and understand what it's doing and if it's necessary.
    (kernel-arguments '("modprobe.blacklist=b43,b43legacy,ssb,bcm43xx,brcm80211,brcmfmac,brcmsmac,bcma"))

    (kernel-loadable-modules (list broadcom-sta))

    (initrd microcode-initrd)

    (firmware (list linux-firmware broadcom-bt-firmware))

    (locale "en_AU.utf8")

    (timezone "Australia/Melbourne")

    (keyboard-layout (keyboard-layout "au"))

    (host-name "computer")

    (users (cons* (user-account
                    (name "tom")
                    (comment "Tom Jones")
                    (group "users")
                    (home-directory "/home/tom")
                    (shell (file-append zsh "/bin/zsh"))
                    (supplementary-groups '("wheel" "netdev" "audio" "video"
                                            "docker"))) %base-user-accounts))

    (packages (append (list git
                            openssh
                            wl-clipboard
                            stow
                            file
                            htop) %base-packages))

    (services
     (append (list (service guix-home-service-type
                            `(("tom" ,%my-home)))
                   (service sddm-service-type)
                   (service plasma-desktop-service-type)
                   (service openssh-service-type)
                   (service bluetooth-service-type)
                   (service docker-service-type)
                   (service containerd-service-type)
                   ;; Increasing max open file descriptors from 1024 in case we have to build
                   ;; from source.
                   (service pam-limits-service-type
                            (list (pam-limits-entry "*"
                                                    'both
                                                    'nofile 4096))))
             ;; Using substitutes otherwise Guix builds everything from scratch!
             (modify-services %desktop-services
               (delete gdm-service-type)
               (guix-service-type config =>
                                  (guix-configuration (inherit config)
                                                      (substitute-urls (append
                                                                        (list
                                                                         "https://substitutes.nonguix.org")
                                                                        %default-substitute-urls))
                                                      (authorized-keys (append
                                                                        (list (local-file
                                                                               "nonguix-signing-key.pub"))
                                                                        %default-authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets (list "/boot/efi"))
                  (keyboard-layout keyboard-layout)))

    (swap-devices (list (swap-space
                          (target (uuid "fb328c53-f7b1-4442-b6ad-85f524219ad6")))))

    (file-systems (cons* (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "CDE4-0C80"
                                         'fat32))
                           (type "vfat"))
                         (file-system
                           (mount-point "/")
                           (device (uuid
                                    "d703a5ca-ad49-4dad-96ba-a3d666b5738e"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
%my-os

;; Disabling till I get a new GPU
;; ((nonguix-transformation-nvidia #:driver nvda-580
;;                                 #:configure-xorg? sddm-service-type)
;;  %my-os)
