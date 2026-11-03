(use-modules (gnu)
             (gnu home services desktop)
             (gnu home services sound)
             (gnu home services)
             (gnu home)
             (gnu packages admin)
             (gnu packages base)
             (gnu packages code)
             (gnu packages commencement)
             (gnu packages compression)
             (gnu packages containers)
             (gnu packages dns)
             (gnu packages ebook)
             (gnu packages file)
             (gnu packages fonts)
             (gnu packages forth)
             (gnu packages gl)
             (gnu packages golang)
             (gnu packages guile)
             (gnu packages gdb)
             (gnu packages image-viewers)
             (gnu packages kde-graphics)
             (gnu packages kde-utils)
             (gnu packages kde-internet)
             (gnu packages python)
             (gnu packages linux)
             (gnu packages libreoffice)
             (gnu packages node)
             (gnu packages package-management)
             (gnu packages pascal)
             (gnu packages multiprecision)
             (gnu packages pdf)
             (gnu packages prolog)
             (gnu packages shells)
             (gnu packages smalltalk)
             (gnu packages sml)
             (gnu packages ssh)
             (gnu packages terminals)
             (gnu packages tmux)
             (gnu packages version-control)
             (gnu packages video)
             (gnu packages vim)
             (gnu packages vulkan)
             (gnu packages web)
             (gnu packages xdisorg)
             (gnu services guix)
             (nongnu packages game-client)
             (nongnu packages linux)
             (nongnu packages mozilla)
             (nongnu packages nvidia)
             (nongnu packages productivity)
             (nongnu system linux-initrd)
             (nonguix transformations)
             (saayix packages sddm)
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
    (packages (append (list calibre
                            docker
                            feh
                            firefox
                            flatpak
                            font-adobe-source-han-sans
                            font-google-noto
                            font-google-noto-emoji
                            font-iosevka-term
                            fzf
                            fpc
                            gforth
                            ghostty
                            gmp
                            go
                            gprolog
                            guile-3.0
                            jq
                            kcalc
                            kdeconnect
                            ;; krita
                            libreoffice
                            neovim
                            node
                            obsidian
                            python
                            smalltalk
                            smlnj
                            steam-nvidia-580
                            the-silver-searcher
                            tmux
                            mpv
                            zathura
                            zathura-pdf-mupdf
                            zsh)))

    (services
     (append (list (service home-dbus-service-type)
                   (service home-pipewire-service-type)) %base-home-services))))

(define %my-os
  (operating-system
    (kernel linux)

    ;; Pulled this straight from nonguix to get wireless working. Might need to
    ;; come back and understand what it's doing and if it's necessary.
    (kernel-arguments '("modprobe.blacklist=b43,b43legacy,ssb,bcm43xx,brcm80211,brcmfmac,brcmsmac,bcma"))

    (initrd microcode-initrd)

    (firmware (list linux-firmware))

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

    (packages (append (list (list isc-bind "utils")
                            file
                            gcc-toolchain
                            git
                            gnu-make
                            gdb
                            htop
                            lm-sensors
                            openssh
                            stow
                            sugar-candy-sddm-theme
                            strace
                            tcpdump
                            unzip
                            vulkan-tools
                            wl-clipboard
                            zip) %base-packages))

    (services
     (append (list (service guix-home-service-type
                            `(("tom" ,%my-home)))
                   (service sddm-service-type
                            (sddm-configuration
                              (theme "sugar-candy")))
                   (service plasma-desktop-service-type)
                   (service openssh-service-type)
                   (service bluetooth-service-type)
                   (service docker-service-type)
                   (service containerd-service-type)
                   ;; Increasing max open file descriptors from 1024 in case we have to build
                   ;; packages from source.
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

((nonguix-transformation-nvidia #:driver nvda-580
                                #:configure-xorg? sddm-service-type)
 %my-os)
