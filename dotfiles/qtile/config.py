import os
import subprocess
from libqtile import qtile
from libqtile.config import Key, Screen, Group, Drag, Click, Match
from libqtile.lazy import lazy
from libqtile import layout, bar, widget, hook

mod = "mod4"
home = os.path.expanduser("~")

# Terminal
terminal = "kitty"
browser = "google-chrome-stable"
file_manager = "spacefm"

# Terminal string for remote controls
terminal_remote_string = "kitty -o allow_remote_controls=yes -o enabled_layouts=tall"
search_selected = f'{terminal_remote_string} google-chrome-stable "google.com/search?q=$(xsel)" &>/dev/null'


# List of hotkeys
keys = [
    # Basics
    Key([mod], "Return", lazy.spawn(terminal), desc="Launches terminal"),
    Key([mod], "d", lazy.spawn("dmenu_run -p 'Run: '"), desc="Launches dmenu"),
    Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),
    Key([mod, "shift"], "q", lazy.window.kill(), desc="Kill active window"),
    Key([mod, "shift"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod, "shift"], "l", lazy.shutdown(), desc="Log out from qtile"),
    # Groups
    Key([mod], "z", lazy.group["I"].toscreen(), desc="Move to group I"),
    Key([mod], "x", lazy.group["II"].toscreen(), desc="Move to group II"),
    Key([mod], "c", lazy.group["III"].toscreen(), desc="Move to group III"),
    Key(
        [mod, "shift"],
        "z",
        lazy.window.togroup("I"),
        desc="Move focused window to group I",
    ),
    Key(
        [mod, "shift"],
        "x",
        lazy.window.togroup("II"),
        desc="Move focused window to group II",
    ),
    Key(
        [mod, "shift"],
        "c",
        lazy.window.togroup("III"),
        desc="Move focused window to group III",
    ),
    # Columns layout
    Key([mod], "Down", lazy.layout.down(), desc="Move down in layout"),
    Key([mod], "Up", lazy.layout.up(), desc="Move up in layout"),
    Key([mod], "Left", lazy.layout.left(), desc="Move left in layout"),
    Key([mod], "Right", lazy.layout.right(), desc="Move right in layout"),
    Key(
        [mod, "shift"],
        "Down",
        lazy.layout.shuffle_down(),
        desc="Move window down in the layout stack",
    ),
    Key(
        [mod, "shift"],
        "Up",
        lazy.layout.shuffle_up(),
        desc="Move window up in the layout stack",
    ),
    Key(
        [mod, "shift"],
        "Left",
        lazy.layout.shuffle_left(),
        desc="Move window to the left in the layout stack",
    ),
    Key(
        [mod, "shift"],
        "Right",
        lazy.layout.shuffle_right(),
        desc="Move window to the right in the layout stack",
    ),
    Key(
        [mod, "control"],
        "Left",
        lazy.layout.grow_left(),
        desc="Grow window to the left",
    ),
    Key(
        [mod, "control"],
        "Right",
        lazy.layout.grow_right(),
        desc="Grow window to the right",
    ),
    Key(
        [mod, "shift", "control"],
        "Left",
        lazy.layout.swap_column_left(),
        desc="Swap column to left",
    ),
    Key(
        [mod, "shift", "control"],
        "Right",
        lazy.layout.swap_column_right(),
        desc="Swap column to the right",
    ),
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Split to window in the same stack",
    ),
    # Tree tabs layout
    Key([mod, "control"], "Up", lazy.layout.section_up(), desc="TreeTab Down"),
    Key([mod, "control"], "Down", lazy.layout.section_down(), desc="TreeTab Up"),
    # Window controls
    Key(
        [mod, "shift"],
        "f",
        lazy.window.toggle_floating(),
        desc="Toggle floating mode to the focused window",
    ),
    Key(
        [mod, "shift"],
        "m",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen to the current focused window",
    ),
    # Hibernate
    Key(
        [mod, "shift"],
        "i",
        lazy.spawn("systemctl hibernate", shell=True),
        desc="Hibernate system.",
    ),
    # Volume control
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5"), desc="Lower Volume by 5%"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5"), desc="Raise Volume by 5%"),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t"), desc="Mute/Unmute Volume"),
    # Quick launch apps
    Key([mod], "m", lazy.spawn(file_manager), desc="Launch file manager"),
    Key(
        [mod],
        "s",
        lazy.spawn("deepin-screenshot"),
        desc="Take screnshot with deepin-screnshot",
    ),
    Key([mod], "b", lazy.spawn(browser), desc="Open browser"),
    Key(
        [mod, "control"],
        "c",
        lazy.spawn(f"code {home}/.config/home-manager"),
        desc="Open QTile configuration",
    ),
    # Utility actions
    Key(
        [mod],
        "f",
        lazy.spawn(search_selected, shell=True),
        desc="Search on the closer chromium instace the text focused",
    ),
]

# Groups name
groupNames = [
    ("I", {"layout": "max"}),
    ("II", {"layout": "max"}),
    (
        "III",
        {
            "layout": "max",
            "matches": [Match(wm_class="Discord"), Match(wm_class="Rustdesk")],
        },
    ),
]

# Add groups to layout and groups hotkeys
groups = [Group(name, **kwargs) for name, kwargs in groupNames]

# Colors
colors = {
    "darkGrey": "#1c1c1c",
    "lightGrey": "#666666",
    "orange": "#ff9f00",
    "lightViolet": "#be67e1",
    "violet": "#833c9f",
    "red": "#ff005b",
    "blue": "#048ac7",
    "lightBlue": "#63e7f0",
    "green": "#73bd78",
}

# List with all layouts used
layouts = [
    layout.Columns(
        num_columns=2,
        border_focus=colors["lightBlue"],
        border_focus_stack=colors["lightBlue"],
        split=False,
    ),
    layout.Columns(
        num_columns=3,
        border_focus=colors["lightBlue"],
        border_focus_stack=colors["lightBlue"],
        split=False,
    ),
    layout.Max(),
    layout.TreeTab(
        fontsize=10,
        sections=["FIRST", "SECOND"],
        section_fontsize=11,
        section_top=10,
        panel_width=320,
        active_bg="141414",
        active_fg="90c435",
        inactive_bg="000000",
        inactive_fg="a0a0a0",
    ),
]

# Widgets
groupbox = widget.GroupBox(
    fontsize=9,
    active=colors["orange"],
    inactive=colors["orange"],
    rounded=False,
    highlight_color=colors["lightGrey"],
    highlight_method="line",
    this_current_screen_border=colors["blue"],
    this_screen_border=colors["violet"],
    other_current_screen_border=colors["darkGrey"],
    other_screen_border=colors["darkGrey"],
    foreground=colors["orange"],
    background=colors["darkGrey"],
)

programsBar = widget.TaskList(
    foreground=colors["lightBlue"],
    background=colors["violet"],
    padding_x=0,
    max_title_width=150,
    margin=0,
    highlight_method="block",
    spacing=3,
    icon_size=0,
)

pomodoro = widget.Pomodoro(
    background=colors["green"],
    color_active=colors["red"],
    color_break=colors["darkGrey"],
    color_inactive=colors["darkGrey"],
)

cpu = widget.CPU(
    foreground=colors["darkGrey"],
    background=colors["green"],
    mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(terminal + " htop")},
    padding=5,
)

cpuThermal = widget.ThermalSensor(
    foreground=colors["darkGrey"],
    background=colors["green"],
    padding=5,
    tag_sensor="Tctl",
)

memory = widget.Memory(
    foreground=colors["lightBlue"],
    background=colors["red"],
    mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(terminal + " htop")},
    padding=5,
)

network = widget.Net(
    format="{down} ↓↑ {up}",
    foreground=colors["orange"],
    background=colors["blue"],
    padding=5,
)

dateTime = widget.Clock(
    format="%d-%m-%Y %a %I:%M %p",
    foreground=colors["blue"],
    background=colors["orange"],
    padding=5,
)

notify = widget.Notify(
    foreground=colors["lightViolet"],
    background=colors["lightGrey"],
    padding=5,
)

systray = widget.Systray()

screens = [
    Screen(
        top=bar.Bar(
            widgets=[
                groupbox,
                programsBar,
                cpu,
                cpuThermal,
                memory,
                network,
                dateTime,
                notify,
                systray,
            ],
            opacity=1.0,
            size=20,
        )
    ),
]

# Mouse stuff
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
main = None
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False

# Floating layout and windows stuff
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirm"),
        Match(wm_class="dialog"),
        Match(wm_class="download"),
        Match(wm_class="error"),
        Match(wm_class="file_progress"),
        Match(wm_class="notification"),
        Match(wm_class="splash"),
        Match(wm_class="toolbar"),
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)

auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True


@hook.subscribe.startup_once
def onLoginFinisced():
    subprocess.call([home + "/.config/qtile/autostart.sh"])


# Look official config for this stuff
wmname = "LG3D"
