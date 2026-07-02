(use-modules (gnu)
             (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu home services sound)
             (gnu home services desktop)
             (gnu packages version-control)
             (gnu packages vim)
             (gnu packages package-management)
             (gnu packages ssh)
             (gnu packages xdisorg)
             (gnu packages shells)
             (gnu packages terminals)
             (gnu packages web)
             (gnu packages tmux)
             (gnu packages docker)
             (gnu packages gl)
             (gnu services guix)
             (nonguix transformations)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu packages mozilla)
             (nongnu system linux-initrd))

(use-service-modules cups
                     desktop
                     networking
                     ssh
                     xorg
                     sddm
                     docker)

(define %my-home
  (home-environment
    (packages (append (list zsh
                            tmux
                            fzf
                            jq
                            docker
                            firefox
                            steam-nvidia-580
                            flatpak)))

    (services
     (append (list (service home-zsh-service-type)
                   (service home-dbus-service-type)
                   (service home-pipewire-service-type)) %base-home-services))))

(define %my-os
  (operating-system
    (kernel linux)

    ;; Pulled this straight from nonguix to get wireless working. Might need to
    ;; come back and understand what it's doing.
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

    (packages (append (list git openssh wl-clipboard neovim) %base-packages))

    (services
     (append (list (service guix-home-service-type
                            `(("tom" ,%my-home)))
                   ;; Apparently GDM doesn't play nicely with Nvidia drivers, so we're replacing
                   ;; it with SDDM.
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
             ;; Using substitutes otherwise everything builds from scratch!
             (modify-services %desktop-services
               ;; See comment above about GDM vs. SDDM.
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
                  (bootloader grub-bootloader)
                  (targets (list "/dev/nvme0n1"))
                  (keyboard-layout keyboard-layout)))

    (mapped-devices (list (mapped-device
                            (source (uuid
                                     "1e2e2948-5bd8-47c2-bbc0-b17bca680c61"))
                            (target "cryptroot")
                            (type luks-device-mapping))))

    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "ext4")
                           (dependencies mapped-devices)) %base-file-systems))))

((nonguix-transformation-nvidia #:driver nvda-580
                                #:configure-xorg? sddm-service-type)
 %my-os)
