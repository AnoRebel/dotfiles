# Custom Commands Module
# Ported from ZSH functions in .zshrc
# Load: `use custom-commands.nu *` or individual imports

# =============================================================================
# ex — Universal archive extractor
# Usage: ex <file>
# =============================================================================
export def ex [file: string] {
    if not ($file | path exists) {
        print $"(ansi red)'($file)' is not a valid file(ansi reset)"
        return
    }
    match ($file | path parse | get extension | str downcase) {
        "tar.bz2" => { tar xjf $file }
        "tbz2"    => { tar xjf $file }
        "tar.gz"  => { tar xzf $file }
        "tgz"     => { tar xzf $file }
        "tar"     => { tar xf $file }
        "bz2"     => { bunzip2 $file }
        "rar"     => { unrar x $file }
        "gz"      => { gunzip $file }
        "zip"     => { unzip $file }
        "Z"       => { uncompress $file }
        "7z"      => { 7z x $file }
        _         => { print $"(ansi red)'($file)' cannot be extracted via ex()(ansi reset)" }
    }
}

# =============================================================================
# nvims — FZF-powered Neovim config switcher
# Usage: nvims [files...]
# =============================================================================
export def nvims [...args: string] {
    let configs = ["default" "AstroNvim" "LazyVim" "NormalNvim" "NvIDE"]
    let config = ($configs | str join "\n" | fzf --prompt $"(char nf_dev_neovim) Neovim Config " --height 50% --layout reverse --border --exit-0 | complete)
    
    if $config.exit_code != 0 or ($config.stdout | str trim) == "" {
        print "Nothing selected"
        return
    }
    
    let chosen = ($config.stdout | str trim)
    let nvim_appname = if $chosen == "default" { "" } else { $chosen }
    
    if $nvim_appname == "" {
        ^nvim ...$args
    } else {
        with-env { NVIM_APPNAME: $nvim_appname } { ^nvim ...$args }
    }
}

# =============================================================================
# mdr — Markdown reader (pandoc → lynx)
# Usage: mdr <file>
# =============================================================================
export def mdr [file: string] {
    ^pandoc $file | ^lynx -stdin
}

# =============================================================================
# rga-fzf — Ripgrep-all with fzf fuzzy search
# Usage: rga-fzf <search_term>
# =============================================================================
export def rga-fzf [query: string] {
    let rg_prefix = "rga --files-with-matches"
    let file = (with-env { FZF_DEFAULT_COMMAND: $"$rg_prefix '($query)'" } {
        fzf --sort --preview $"[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" --phony -q $query --bind $"change:reload:$rg_prefix {q}" --preview-window "70%:wrap"
    } | complete)
    
    if $file.exit_code == 0 and ($file.stdout | str trim) != "" {
        let selected = ($file.stdout | str trim)
        print $"opening ($selected)"
        xdg-open $selected
    }
}

# =============================================================================
# yz — Yazi file manager with directory change on exit
# Usage: yz [path]
# Uses def-env so the cd persists after yazi exits
# =============================================================================
export def --env yz [...args: string] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    
    # We can't pass --cwd-file directly to yazi in all versions.
    # Using yazi's cwd-file feature if available.
    let cmd_args = ($args | append ["--cwd-file" $tmp])
    ^yazi ...$cmd_args
    
    if ($tmp | path exists) {
        let cwd = (open $tmp | str trim)
        if $cwd != "" and $cwd != $env.PWD {
            cd $cwd
        }
    }
    
    rm -f $tmp
}

# =============================================================================
# mkcd — Create directory and cd into it
# Usage: mkcd <path>
# =============================================================================
export def --env mkcd [dir: string] {
    mkdir $dir
    cd $dir
}

# =============================================================================
# myip — Get public IP address
# Usage: myip
# =============================================================================
export def myip [] {
    ^dig +short myip.opendns.com @resolver1.opendns.com
}

# =============================================================================
# wetha — Dar es Salaam weather
# Usage: wetha
# =============================================================================
export def wetha [] {
    ^curl -s "http://wttr.in/~Dar-es-salaam" | lines | first 38 | str join "\n"
}

# =============================================================================
# pgadmin — Start PHP adminer in background
# Usage: pgadmin
# =============================================================================
export def pgadmin [] {
    cd ~/adminer
    ^nohup php -S 127.0.0.1:3066 out> logs & 
    ^brave-browser 127.0.0.1:3066 &
    cd $env.HOME
}

# =============================================================================
# alert — Desktop notification for last command
# Usage: sleep 10; alert
# =============================================================================
export def alert [] {
    let last_exit = $env.LAST_EXIT_CODE
    let icon = if $last_exit == 0 { "terminal" } else { "error" }
    let last_cmd = (history | last | get command)
    ^notify-send -u low -i $icon $last_cmd
}

# =============================================================================
# bgnotify_formatted — Background job notification (for long-running commands)
# This is called by the bgnotify plugin pattern.
# In Nushell, we use a post-execution hook instead.
# =============================================================================
export def bgnotify_formatted [exit_status: int, cmd: string, elapsed: string] {
    let title = if $exit_status == 0 { "Done." } else { "Tha Hell.." }
    ^notify-send $"($title) -- after ($elapsed)s" $cmd
}
