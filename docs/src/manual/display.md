# Display widgets

We have already encountered [GtkLabel](@ref), which is used to display text. GTK has a few other widgets that are useful for displaying information.

## [GtkSpinner](https://docs.gtk.org/gtk4/class.Spinner.html)

This is a simple widget that optionally shows an animated spinning icon. It's used to indicate to the user that something is happening.

The widget is constructed using `GtkSpinner()`. There are just two methods, `start` to display the spinning icon and `stop` to not display it.

To check if the spinner is spinning, use the "spinning" property or the `spinning` getter method.

## [GtkProgressBar](https://docs.gtk.org/gtk4/class.ProgressBar.html)

This widget shows a progress bar and optionally text.

```julia
win = GtkWindow("Progress bar")
progbar = GtkProgressBar()
push!(win, progbar)
```

The fractional progress (between 0.0 and 1.0) can be set using the `fraction` setter or the "fraction" property:
```julia
fraction(progbar, 0.5)
progbar.fraction
```

You can show text which might, for example, say something about what is happening or an estimated time left:
```julia
Gtk4.text(progbar, "11 seconds remaining")
```

For processes with no well defined concept of progress, you can periodically use the `pulse` method to cause the progress bar to show a back and forth motion (think "Knight Rider"), reassuring the user that something is continuing to happen:

```julia
Gtk4.pulse(progbar) # moves the progress bar a little
```

The step size (in fractional units) for `pulse` can be set using `Gtk4.pulse_step`.

## [GtkPicture](https://docs.gtk.org/gtk4/class.Picture.html) and [GtkImage](https://docs.gtk.org/gtk4/class.Image.html)

These two widgets can be used to display an image. `GtkPicture` shows the image at its natural size, while `GtkImage` shows it at a fixed, potentially smaller size (for example, an icon). The image can be set in a constructor or be set by a method.

For `GtkPicture`, there are constructors that read from a file (in PNG, JPEG, or TIFF format), either using a `GFile` object or a filename. Alternatively you can construct a `GtkPicture` from a `GdkPixbuf` or `GdkPaintable`.
