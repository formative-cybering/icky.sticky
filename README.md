![icky-sticky](/icky.png)

# Icky Sticky

Degenerate sticky notes

CLI:

```sh
# start daemon
icky

# add note
icky "buy milk"
```

Notes are ephemeral, when you close them, they are gone forever. There is no persistance layer (yet...)

hyprland.conf example:

```hyprlang
exec-once = icky

windowrule = float, class:^(icky.sticky)
windowrule = pin, class:^(icky.sticky)
windowrule = size 500 200, class:^(icky.sticky)
windowrule = noinitialfocus, class:^(icky.sticky)
```
---

Build: requires vala, gtk4 + glib2

```sh
./build.sh
```

Run:

```sh
./icky
```

---

Todo:

- [ ] Add config for custom css
