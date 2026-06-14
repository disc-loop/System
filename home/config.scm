(define-module (guix-home-config)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu services)
  #:use-module (gnu system shadow))

(define home-config
  (home-environment
    (services
      (append (list (service home-zsh-service-type) %base-home-services))))

home-config
