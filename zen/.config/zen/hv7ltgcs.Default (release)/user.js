// Shrink Zen's UI on the 13" 2560x1600 panel (Hyprland scale 2 => UI is 200%).
// Positive value overrides the compositor scale: 1.6 = 80% of the default size.
// Web content shrinks too; adjust per-site with Ctrl +/- or set a default zoom.
// Remove this line (and reset in about:config) to go back to following Hyprland.
user_pref("layout.css.devPixelsPerPx", "1.6");
