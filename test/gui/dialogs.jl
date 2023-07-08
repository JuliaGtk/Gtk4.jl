using Test, Gtk4

@testset "dialogs" begin

main_window = GtkWindow("Dialog example")

r = ask_dialog("May I ask you a question?",main_window; timeout = 0.25)
@test r == false

info_dialog("Here's some information", main_window; timeout = 0.25)
warn_dialog("Here's some alarming information", main_window; timeout = 0.25)
error_dialog("Here's an error", main_window; timeout = 0.25)

open_dialog("Pick a file to open", main_window; timeout = 0.25)
open_dialog("Pick a file to open", main_window, ["*.png"]; timeout = 0.25)
save_dialog("Pick a filename", main_window; timeout = 0.25)

color_dialog("What is your favorite color?", main_window; timeout = 0.25)

input_dialog("What is the meaning of life, the universe, and everything?", "42", (("Cancel", 0), ("Accept", 1)), main_window; timeout = 0.25)

dlg = GtkDialog("General dialog",
                Dict("Cancel" => Gtk4.ResponseType_CANCEL,
                     "OK"=> Gtk4.ResponseType_ACCEPT),
                      Gtk4.DialogFlags_MODAL )
show(dlg)
destroy(dlg)
destroy(main_window)

end
