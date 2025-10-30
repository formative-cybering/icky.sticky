![icky-sticky](/sticky.png)

# Icky Sticky

Degenerate sticky notes

CLI:

```sh
# start daemon
sticky

# add note
sticky "buy milk"
```

Notes are ephemeral, when you close them, they are gone forever. There is no persistance layer (yet...)

Styling: `~/.config/icky/sticky.css`

```css
/* containing window */
window#icky-sticky {
  background-color: rgba(0, 0, 0, 0);
  background-image: none;
}
window#icky-sticky > * {
  background-color: rgba(0, 0, 0, 0);
}

/* internal note */
#sticky-icky {
  font-size: 30pt;
  font-family: "Boxcutter";
  background-color: rgba(0, 0, 0, 0);
  background-image: none;
}
```

`hyprland.conf` example:

```hyprlang
exec-once = sticky

windowrule = float, class:^(icky.sticky)
windowrule = pin, class:^(icky.sticky)
windowrule = size 500 200, class:^(icky.sticky)
windowrule = noinitialfocus, class:^(icky.sticky)
```

Tips:

Nice look when setting background transparent and hyprland background blur for frosted glass effect!

---

Build: requires vala, gtk4 + glib2

```sh
./build.sh
```

Run:

```sh
./sticky
```
