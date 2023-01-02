# Gtk4.jl

*Julia Bindings for Gtk version 4.x.*

## Introduction

Gtk4.jl is a Julia package providing bindings for the Gtk library: [https://www.gtk.org/](https://www.gtk.org/)

Complete Gtk documentation is available at [https://www.gtk.org/docs/](https://www.gtk.org/docs/)

## Usage

  * See [Getting Started](@ref) for an introduction to using the package, adapted from the [Gtk.jl manual](https://juliagraphics.github.io/Gtk.jl/latest/).
  * See [Gtk4 Reference](@ref) for an API reference automatically generated from docstrings.
  * See [Differences between Gtk.jl and Gtk4.jl](@ref) for a summary of the differences between this package and Gtk.jl.

## History

This package was adapted from Gtk.jl, which was written by [Jameson Nash and others](https://github.com/JuliaGraphics/Gtk.jl/contributors) and supported GTK versions 2 and 3. With version 4 there were so many changes to the GTK API that it would have been messy to try to support it and previous versions in the same package. Note that much of the GLib/GObject functionality that underlies GTK is largely the same code as in Gtk.jl. Some changes were made to try to take better advantage of GObject introspection or to remove old code that was no longer necessary in recent versions of Julia.
