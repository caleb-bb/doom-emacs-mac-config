(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("166a2faa9dc5b5b3359f7a31a09127ebf7a7926562710367086fcc8fc72145da" "d12b1d9b0498280f60e5ec92e5ecec4b5db5370d05e787bc7cc49eae6fb07bc0" "dccf4a8f1aaf5f24d2ab63af1aa75fd9d535c83377f8e26380162e888be0c6a9" "ffafb0e9f63935183713b204c11d22225008559fa62133a69848835f4f4a758c" default))
 '(safe-local-variable-values
   '((eval let*
      ((root
        (locate-dominating-file default-directory ".dir-locals.el"))
       (cargo-files
        (file-expand-wildcards
         (concat root "native/*/Cargo.toml"))))
      (setq-local lsp-rust-analyzer-linked-projects
       (vconcat
        (mapcar
         (lambda
           (f)
           (file-relative-name f root))
         cargo-files)))))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
