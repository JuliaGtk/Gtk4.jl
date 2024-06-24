# Actions

[Actions](https://docs.gtk.org/gtk4/actions.html) are another way of associating callbacks with widgets. While they are a bit more complicated to set up, they have a few advantages over connecting to widget signals such as "clicked".

Actions are based on an interface `GAction`, the most straightforward implementation of which is `GSimpleAction`. Actions have a property "name" which must be a non-empty string consisting of alphanumeric characters, dashes ('-'), and dots ('.'). Actions also have a method `activate` that takes an optional parameter argument (more on those later).

Some widgets, including `GtkButton`, `GtkToggleButton`, and `GtkCheckButton`, (to be precise, widgets that implement the `GtkActionable` interface) have a property "action-name" that sets an associated action.

Let's say we want to define an action that closes a window. We could use
```julia
using Gtk4, Gtk4.GLib

win = GtkWindow("Action demo", 400, 200)

b = GtkButton("Click to close this window")
b.action_name = "win.close"
push!(win,b)

function close_action_cb(a, par)::Nothing  # important to return nothing!
    close(win)
end

action_group = GSimpleActionGroup()
add_action(GActionMap(action_group), "close", close_action_cb)
push!(win, Gtk4.GLib.GActionGroup(action_group), "win")
```
Let's go through this. First we created the window and button and set the button's action name to "win.close". Next we created an action group. Then we used the helper method `add_action` to create an action with the name "close", connect a callback for the action's "activate" signal, and add the action to the action group. Finally we added the action group to the window and associated it with a prefix "win".

For what it accomplishes, this code looks a bit convoluted.
Why did we set the button's action name to "win.close" rather than "close", which is the action's name? Each action is put in a group, which has its own prefix, in this case "win". The action's global name is "win.close" because it was added to the "win" group. Often applications define an "app" group for application-wide actions, and each window has its own "win" group for window-specific actions. You can even define action groups for individual widgets. When we set an action name for the button, GTK looks for a group named "win", starting with the button itself and then working its way up the widget hierarchy. In our case it found that group associated with the window.

You are probably asking yourself, why do it this way when we could have just connected `close_cb` to the button's "clicked" signal? Here are a few reasons to use actions:

1. Multiple widgets can point to the same action. For example, we could have a menu item for closing the window. Actions can reduce code duplication.
2. Actions can be disabled. Let's say we want to temporarily turn off the "close" action. We can do this by setting the action's property "enabled" to false. Any widgets that are connected to this action will be greyed out automatically, indicating to users that they don't do anything.
3. If you use `GtkApplication` and `GtkApplicationWindow`, you get action groups associated with the application and windows for free since these two widget classes define the interface `GActionGroup`. So that saves you from having to create a `GSimpleActionGroup` and add it to the window.
4. If you use Builder, you can set the action names and targets for widgets in XML.

## Stateful actions

The action "close" in the example above was a stateless action.
All one can do is "activate" it, which calls a function.
It's possible to associate a state with an action too.

Here is a simple example of a stateful action:
```julia
using Gtk4, Gtk4.GLib

win = GtkWindow("Fullscreen action demo", 400, 200)

b = GtkButton("Click to change fullscreen state"; action_name="win.fullscreen")
push!(win,b)

function fullscreen_action_cb(a, v)::Nothing
    if v[Bool]
        Gtk4.fullscreen(win)
    else
        Gtk4.unfullscreen(win)
    end
    Gtk4.GLib.set_state(a, v)
end

action_group = GSimpleActionGroup()
add_stateful_action(GActionMap(action_group), "fullscreen", false, fullscreen_action_cb)
push!(win, Gtk4.GLib.GActionGroup(action_group), "win")
```

Here we used `add_stateful_action` to create an action named "fullscreen" that has a boolean state associated with it. The type of the state is taken from the initial state argument, which in this case was `false`.
The callback is connected to the action's "change-state" signal.

In the callback, the argument `v` is a `GVariant`, which is sort of a container type in GLib that is used in the action system.
To read the state value from the container we used `v[Bool]`.

Note that you have to call `set_state` in the callback or else the state will not be updated!

## A more complicated example

```julia
using Gtk4, Gtk4.GLib

win = GtkWindow("Radio button demo", 400, 200)
win[] = box = GtkBox(:v)

b1 = GtkToggleButton("Option 1"; action_name = "win.option", action_target=GVariant("1"))
push!(box, b1)
push!(box, GtkToggleButton("Option 2"; action_name = "win.option", action_target=GVariant("2"), group = b1))
push!(box, GtkToggleButton("Option 3"; action_name = "win.option", action_target=GVariant("3"), group = b1))

lbl = GtkLabel("1")
push!(box, lbl)

function opt_action_cb(a,v)::Nothing
    lbl.label = v[String]
    Gtk4.GLib.set_state(a,v)
end

action_group = GSimpleActionGroup()
add_stateful_action(GActionMap(action_group), "option", String, "1", opt_action_cb)
push!(win, Gtk4.GLib.GActionGroup(action_group), "win")
```

## Actions in an application

As mentioned above, the objects `GtkApplication` and `GtkApplicationWindow` implement the `GActionMap` interface, so there is no need to create a `GSimpleActionGroup` and add it to the window. For `GtkApplicationWindow`s, you can add window-associated actions using `add_action(GActionMap(win), "fullscreen", fullscreen_cb)`. Assuming you have created a `GtkApplication` called `app`, you can add actions to the application using `add_action(GActionMap(app), "fullscreen", fullscreen_cb)`.