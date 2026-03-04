# dotfiles
Personal dotfiles

## One-liner to install dotfiles on new device

### 1. The **Init & Apply** One-Liner
   
***It initializes chezmoi with your repo and immediately applies the files to your home directory:***

> ` sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply loloMD`

### 2. The "Init Only" One-Liner

***To be cautious and want to inspect what will happen before the files are written to your system, use this***

> `sh -c "$(curl -fsLS get.chezmoi.io)" -- init loloMD`

Note: After running this, you would need to run `./bin/chezmoi managed` OR `bin/chezmoi diff` to see changes and `bin/chezmoi apply` to finalize them.
