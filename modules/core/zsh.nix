{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    setOptions = [
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_SAVE_NO_DUPS"
    ];
  };
}
