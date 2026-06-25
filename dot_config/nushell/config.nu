# Nushell Config File
# Refactored to mirror .zshrc functionality using official tool integrations
# version = "0.111.0"

# =============================================================================
# THEMES
# =============================================================================

let dark_theme = {
    separator: white
    leading_trailing_space_bg: { attr: n }
    header: green_bold
    empty: blue
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    date: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray
    search_result: {bg: red fg: white}
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
}

let light_theme = {
    separator: dark_gray
    leading_trailing_space_bg: { attr: n }
    header: green_bold
    empty: blue
    bool: dark_cyan
    int: dark_gray
    filesize: cyan_bold
    duration: dark_gray
    date: purple
    range: dark_gray
    float: dark_gray
    string: dark_gray
    nothing: dark_gray
    binary: dark_gray
    cell-path: dark_gray
    row_index: green_bold
    record: dark_gray
    list: dark_gray
    block: dark_gray
    hints: dark_gray
    search_result: {fg: white bg: red}
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_purple_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
}

# =============================================================================
# MAIN CONFIGURATION
# =============================================================================

$env.config = {
    show_banner: false

    ls: {
        use_ls_colors: true
        clickable_links: true
    }

    rm: {
        always_trash: false
    }

    table: {
        mode: rounded
        index_mode: always
        show_empty: true
        padding: { left: 1, right: 1 }
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
            truncating_suffix: "..."
        }
        header_on_separator: false
    }

    error_style: "fancy"

    datetime_format: {}

    explore: {
        status_bar_background: {fg: "#1D1F21", bg: "#C4C9C6"}
        command_bar_text: {fg: "#C4C9C6"}
        highlight: {fg: "black", bg: "yellow"}
        status: {
            error: {fg: "white", bg: "red"}
            warn: {}
            info: {}
        }
        table: {
            split_line: {fg: "#404040"}
            selected_cell: {bg: light_blue}
            selected_row: {}
            selected_column: {}
        }
    }

    # History — dedup like zsh's histignoredups, use sqlite for better performance
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }

    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
            enable: true
            max_results: 100
            completer: null
        }
    }

    cursor_shape: {
        emacs: line
        vi_insert: block
        vi_normal: underscore
    }

    color_config: $dark_theme
    footer_mode: 25
    float_precision: 2
    buffer_editor: $env.EDITOR
    use_ansi_coloring: true
    bracketed_paste: true
    edit_mode: emacs
    shell_integration: {
        osc2: true
        osc7: true
        osc8: true
        osc9_9: true
        osc133: true
        osc633: true
        reset_application_mode: true
    }
    render_right_prompt_on_last_line: false
    use_kitty_protocol: true
    highlight_resolved_externals: true

    # =========================================================================
    # HOOKS
    # =========================================================================
    hooks: {
        pre_prompt: [{|| null }]
        pre_execution: [
            {|| $env.CMD_START_TIME = (date now | format date '%s' | into int) }
        ]
        env_change: {
            PWD: [{|before, after| null }]
        }
        display_output: "if (term size).columns >= 100 { table -e } else { table }"
        command_not_found: {|| null }
    }

    # =========================================================================
    # MENUS
    # =========================================================================
    menus: [
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: columnar
                columns: 4
                col_width: 20
                col_padding: 2
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4
                col_width: 20
                col_padding: 2
                selection_rows: 4
                description_rows: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
    ]

    # =========================================================================
    # KEYBINDINGS (mirrors your ZSH readline + emacs habits)
    # =========================================================================
    keybindings: [
        # Tab completion
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        # Ctrl+R → history search (replaces fzf-history-widget)
        {
            name: history_menu
            modifier: control
            keycode: char_r
            mode: [emacs vi_insert vi_normal]
            event: { send: menu name: history_menu }
        }
        # F1 → help
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs vi_insert vi_normal]
            event: { send: menu name: help_menu }
        }
        # Shift+Tab → previous completion
        {
            name: completion_previous_menu
            modifier: shift
            keycode: backtab
            mode: [emacs vi_normal vi_insert]
            event: { send: menuprevious }
        }
        # Arrow keys
        {
            name: move_up
            modifier: none
            keycode: up
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: menuup} {send: up}] }
        }
        {
            name: move_down
            modifier: none
            keycode: down
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: menudown} {send: down}] }
        }
        {
            name: move_left
            modifier: none
            keycode: left
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: menuleft} {send: left}] }
        }
        {
            name: move_right_or_take_history_hint
            modifier: none
            keycode: right
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: historyhintcomplete} {send: menuright} {send: right}] }
        }
        # Ctrl+arrow word movement
        {
            name: move_one_word_left
            modifier: control
            keycode: left
            mode: [emacs vi_normal vi_insert]
            event: {edit: movewordleft}
        }
        {
            name: move_one_word_right
            modifier: control
            keycode: right
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: historyhintwordcomplete} {edit: movewordright}] }
        }
        # Home/End
        {
            name: move_to_line_start
            modifier: none
            keycode: home
            mode: [emacs vi_normal vi_insert]
            event: {edit: movetolinestart}
        }
        {
            name: move_to_line_start_ctrl_a
            modifier: control
            keycode: char_a
            mode: [emacs vi_normal vi_insert]
            event: {edit: movetolinestart}
        }
        {
            name: move_to_line_end
            modifier: none
            keycode: end
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: historyhintcomplete} {edit: movetolineend}] }
        }
        {
            name: move_to_line_end_ctrl_e
            modifier: control
            keycode: char_e
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: historyhintcomplete} {edit: movetolineend}] }
        }
        # Ctrl+Home/End
        {
            name: move_to_line_start_ctrl_home
            modifier: control
            keycode: home
            mode: [emacs vi_normal vi_insert]
            event: {edit: movetolinestart}
        }
        {
            name: move_to_line_end_ctrl_end
            modifier: control
            keycode: end
            mode: [emacs vi_normal vi_insert]
            event: {edit: movetolineend}
        }
        # Ctrl+P/N → up/down (Emacs)
        {
            name: move_up_ctrl_p
            modifier: control
            keycode: char_p
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: menuup} {send: up}] }
        }
        {
            name: move_down_ctrl_n
            modifier: control
            keycode: char_n
            mode: [emacs vi_normal vi_insert]
            event: { until: [{send: menudown} {send: down}] }
        }
        # Backspace / Delete
        {
            name: backspace
            modifier: none
            keycode: backspace
            mode: [emacs vi_insert]
            event: {edit: backspace}
        }
        {
            name: ctrl_backspace
            modifier: control
            keycode: backspace
            mode: [emacs vi_insert]
            event: {edit: backspaceword}
        }
        {
            name: delete
            modifier: none
            keycode: delete
            mode: [emacs vi_insert]
            event: {edit: delete}
        }
        {
            name: ctrl_delete
            modifier: control
            keycode: delete
            mode: [emacs vi_insert]
            event: {edit: delete}
        }
        {
            name: ctrl_h_backspace
            modifier: control
            keycode: char_h
            mode: [emacs vi_insert]
            event: {edit: backspace}
        }
        {
            name: ctrl_w_backspace_word
            modifier: control
            keycode: char_w
            mode: [emacs vi_insert]
            event: {edit: backspaceword}
        }
        # Vi normal backspace
        {
            name: vi_backspace
            modifier: none
            keycode: backspace
            mode: vi_normal
            event: {edit: moveleft}
        }
        # Enter
        {
            name: enter
            modifier: none
            keycode: enter
            mode: emacs
            event: {send: enter}
        }
        # Ctrl+B/F → left/right (Emacs)
        {
            name: ctrl_b_left
            modifier: control
            keycode: char_b
            mode: emacs
            event: { until: [{send: menuleft} {send: left}] }
        }
        {
            name: ctrl_f_right
            modifier: control
            keycode: char_f
            mode: emacs
            event: { until: [{send: historyhintcomplete} {send: menuright} {send: right}] }
        }
        # Ctrl+G/Z → redo/undo
        {
            name: ctrl_g_redo
            modifier: control
            keycode: char_g
            mode: emacs
            event: {edit: redo}
        }
        {
            name: ctrl_z_undo
            modifier: control
            keycode: char_z
            mode: emacs
            event: {edit: undo}
        }
        # Ctrl+Y → paste
        {
            name: ctrl_y_paste
            modifier: control
            keycode: char_y
            mode: emacs
            event: {edit: pastecutbufferbefore}
        }
        # Ctrl+W/K/U → cut operations
        {
            name: ctrl_w_cut_word
            modifier: control
            keycode: char_w
            mode: emacs
            event: {edit: cutwordleft}
        }
        {
            name: ctrl_k_cut_to_end
            modifier: control
            keycode: char_k
            mode: emacs
            event: {edit: cuttoend}
        }
        {
            name: ctrl_u_cut_from_start
            modifier: control
            keycode: char_u
            mode: emacs
            event: {edit: cutfromstart}
        }
        {
            name: ctrl_t_swap
            modifier: control
            keycode: char_t
            mode: emacs
            event: {edit: swapgraphemes}
        }
        # Alt+arrow / Alt+letter word movement
        {
            name: alt_left
            modifier: alt
            keycode: left
            mode: emacs
            event: {edit: movewordleft}
        }
        {
            name: alt_right
            modifier: alt
            keycode: right
            mode: emacs
            event: { until: [{send: historyhintwordcomplete} {edit: movewordright}] }
        }
        {
            name: alt_b
            modifier: alt
            keycode: char_b
            mode: emacs
            event: {edit: movewordleft}
        }
        {
            name: alt_f
            modifier: alt
            keycode: char_f
            mode: emacs
            event: { until: [{send: historyhintwordcomplete} {edit: movewordright}] }
        }
        # Alt+delete/backspace word deletion
        {
            name: alt_delete
            modifier: alt
            keycode: delete
            mode: emacs
            event: {edit: deleteword}
        }
        {
            name: alt_backspace
            modifier: alt
            keycode: backspace
            mode: emacs
            event: {edit: backspaceword}
        }
        {
            name: alt_m_backspace
            modifier: alt
            keycode: char_m
            mode: emacs
            event: {edit: backspaceword}
        }
        # Alt+D → cut word right
        {
            name: alt_d_cut_word_right
            modifier: alt
            keycode: char_d
            mode: emacs
            event: {edit: cutwordright}
        }
        # Alt+U/L/C → case operations
        {
            name: alt_u_upper
            modifier: alt
            keycode: char_u
            mode: emacs
            event: {edit: uppercaseword}
        }
        {
            name: alt_l_lower
            modifier: alt
            keycode: char_l
            mode: emacs
            event: {edit: lowercaseword}
        }
        {
            name: alt_c_capitalize
            modifier: alt
            keycode: char_c
            mode: emacs
            event: {edit: capitalizechar}
        }
        # Ctrl+X → next page in menu
        {
            name: ctrl_x_next_page
            modifier: control
            keycode: char_x
            mode: emacs
            event: { send: menupagenext }
        }
        # Ctrl+L → clear screen
        {
            name: ctrl_l_clear
            modifier: control
            keycode: char_l
            mode: [emacs vi_normal vi_insert]
            event: { send: clearscreen }
        }
        # Ctrl+D → quit
        {
            name: ctrl_d_quit
            modifier: control
            keycode: char_d
            mode: [emacs vi_normal vi_insert]
            event: { send: ctrld }
        }
        # Ctrl+C → cancel
        {
            name: ctrl_c_cancel
            modifier: control
            keycode: char_c
            mode: [emacs vi_normal vi_insert]
            event: { send: ctrlc }
        }
        # Ctrl+O → open editor
        {
            name: ctrl_o_editor
            modifier: control
            keycode: char_o
            mode: [emacs vi_normal vi_insert]
            event: { send: openeditor }
        }
        # Ctrl+Q → search history
        {
            name: ctrl_q_search
            modifier: control
            keycode: char_q
            mode: [emacs vi_normal vi_insert]
            event: { send: searchhistory }
        }
        # Escape
        {
            name: escape
            modifier: none
            keycode: escape
            mode: [emacs vi_normal vi_insert]
            event: { send: esc }
        }
    ]
}

# =============================================================================
# LOAD CUSTOM COMMANDS (from scripts/ directory via NU_LIB_DIRS)
# =============================================================================

use custom-commands.nu *

# =============================================================================
# LOAD TOOL INIT FILES (generated by env.nu)
# =============================================================================

# =============================================================================
# LOAD TOOL INIT FILES (generated by env.nu — files always exist)
# =============================================================================

# mise — Official Nushell integration (https://mise.jdx.dev/installing-mise)
source ($nu.default-config-dir | path join "mise.nu")

# zoxide — official pattern: env.nu generates .zoxide.nu, config.nu `source`s it
source ($nu.default-config-dir | path join ".zoxide.nu")
alias z = __zoxide_z
alias zi = __zoxide_zi

# atuin — env.nu generates .atuin.nu, config.nu `source`s it
source ($nu.default-config-dir | path join ".atuin.nu")
source ~/.local/share/atuin/pty-proxy-init.nu
source ~/.local/share/atuin/init.nu

# thefuck — no native nu init; define wrapper inline
# Always defined; errors at runtime if thefuck isn't installed
def fuck [] {
    let last_cmd = (history | last | get command)
    let corrected = (^thefuck $last_cmd | complete)
    if $corrected.exit_code == 0 {
        nu -c ($corrected.stdout | str trim)
    }
}

# =============================================================================
# ALIASES
# =============================================================================

# --- Quick utilities ---
alias c = clear
alias q = exit
alias vi = avim
alias vim = avim
alias copy = rsync -rP
alias py = python3
alias lg = lazygit

# --- Kitty integration ---
alias icat = kitty +kitten icat
alias d = kitty +kitten diff
alias s = kitty +kitten ssh

# --- Editor shortcuts ---
alias zshrc = avim ~/.zshrc
alias bashrc = avim ~/.bashrc
alias vimrc = avim ~/.local/share/anonvim/avim/init.lua
alias nucfg = avim ~/.config/nushell/config.nu
alias nuenv = avim ~/.config/nushell/env.nu

# --- System maintenance (Arch Linux) ---
def ua-drop-caches [] { sudo paccache -rk3; yay -Sc --aur --noconfirm }
def ua-update-all [] {
    let tmpfile = (mktemp)
    sudo true
    rate-mirrors --save $tmpfile arch --max-delay 21600
    sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup
    sudo mv $tmpfile /etc/pacman.d/mirrorlist
    ua-drop-caches
    yay -Syyu --noconfirm
}

# --- File listing with eza (replaces ZSH ls aliases exactly) ---
alias ls = eza -hUumF --icons --git --git-repos --color=automatic --color-scale=all --smart-group
alias l = eza -l
alias la = eza -a
alias lr = eza -ar
alias lla = eza -aHl
alias llr = eza -aHlr
alias lt = eza --tree --level=2 --git-ignore
alias llt = eza -l --tree --git-ignore

# =============================================================================
# FILE OPENING BY EXTENSION (ZSH `alias -s` equivalent)
# =============================================================================
# ZSH: `alias -s avi=mplayer` → running `file.avi` opens it with mplayer.
# Nushell has no suffix aliases. Instead, define an `open-media` dispatcher
# that maps file extensions to the right programs from $env vars.

def --env open-media [file: string] {
    let ext = ($file | path parse | get extension | str downcase)
    let video_exts = [avi flv mkv mp4 mpeg mpg ogv wmv]
    let audio_exts = [flac mp3 ogg wav]
    let image_exts = [gif jpeg jpg png]
    let doc_exts = [djvu pdf ps]
    let text_exts = [txt md log conf cfg yaml yml toml json nu]
    let ebook_exts = [epub]
    let comic_exts = [cbr cbz]

    if $ext in $video_exts {
        ^$env.PLAYER $file
    } else if $ext in $audio_exts {
        ^$env.MUSICER $file
    } else if $ext in $image_exts {
        ^$env.IMAGEVIEWER $file
    } else if $ext in $doc_exts {
        ^$env.READER $file
    } else if $ext in $text_exts {
        ^$env.EDITOR $file
    } else if $ext in $ebook_exts {
        ^$env.EBOOKER $file
    } else if $ext in $comic_exts {
        ^$env.COMICER $file
    } else {
        ^xdg-open $file
    }
}

# =============================================================================
# DOTBARE (bare git repo for dotfiles)
# =============================================================================
def dotbare [...args] {
    ^git --git-dir $env.DOTBARE_DIR --work-tree $env.DOTBARE_TREE ...$args
}

# =============================================================================
# PROMPT
# =============================================================================
# Using Nushell's built-in prompts defined in env.nu's create_left_prompt /
# create_right_prompt. Uncomment below for Starship instead:
#
# if (which starship | is-not-empty) {
#     let starship_hook = (^starship init nushell | complete)
#     if $starship_hook.exit_code == 0 {
#         $starship_hook.stdout | save -f ($nu.default-config-dir | path join ".starship.nu")
#         source .starship.nu
#     }
# }
