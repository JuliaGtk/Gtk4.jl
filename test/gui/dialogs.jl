using Test, Gtk4

@testset "dialogs" begin

main_window = GtkWindow("Dialog example")

r = ask_dialog("May I ask you a question?",main_window; timeout = 0.25)
@test r == false

info_dialog("Here's some information", main_window; timeout = 0.25)
warn_dialog("Here's some alarming information", main_window; timeout = 0.25)
error_dialog("Here's an error", main_window; timeout = 0.25)

open_dialog("Pick a file to open", main_window; timeout = 0.25)
save_dialog("Pick a filename", main_window; timeout = 0.25)

color_dialog("What is your favorite color?", main_window; timeout = 0.25)

end
