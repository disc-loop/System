(use-modules 
  (gnu)
  (gnu packages version-control)
  (gnu packages vim)
  (gnu packages package-management)
  (gnu packages ssh)
  (gnu packages xdisorg)
  (gnu packages shells)
  (gnu packages terminals)
  (gnu packages web)
  (gnu packages librewolf)
  (gnu packages tmux)
  (gnu packages docker)
  (gnu packages gl)
  (nonguix transformations)
  (nongnu packages linux)
  (nongnu packages mozilla)
  (nongnu packages nvidia)
  (nongnu system linux-initrd))
(use-service-modules cups desktop networking ssh xorg sddm docker)

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
                    (comment "Thomas Jones")
                    (group "users")
                    (home-directory "/home/tom")
                    (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))
                  %base-user-accounts))

    (packages (append 
                (list 
                  git 
                  openssh
                  neovim 
                  wl-clipboard
                  zsh
                  fzf
                  nix
                  jq
                  tmux
                  docker
                  firefox
		  librewolf
                  mesa 
                  mesa-utils
                  steam-nvidia-580) 
                  %base-packages))

    (services 
      (append 
        (list 
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
            (list (pam-limits-entry "*" 'both 'nofile 4096))))
        ;; Using substitutes otherwise everything builds from scratch! 
        (modify-services %desktop-services
          ;; See comment above about GDM vs. SDDM.
	  (delete gdm-service-type)
          (guix-service-type config => (guix-configuration
            (inherit config)
            (substitute-urls
             (append (list "https://substitutes.nonguix.org")
               %default-substitute-urls))
            (authorized-keys
             (append (list (local-file "nonguix-signing-key.pub"))
               %default-authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets (list "/boot/efi"))
                  (keyboard-layout keyboard-layout)))

    (mapped-devices (list (mapped-device
                            (source (uuid
                                     "11b93e9d-78b6-4e93-94e0-4e1088f90ab3"))
                            (target "cryptroot")
                            (type luks-device-mapping))))

    (file-systems (cons* (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "F502-5F2C" 'fat32))
                           (type "vfat"))
                         (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "ext4")
                           (dependencies mapped-devices)) 
		       %base-file-systems))))

((nonguix-transformation-nvidia 
   #:driver nvda-580
   #:configure-xorg? sddm-service-type) 
 %my-os)
