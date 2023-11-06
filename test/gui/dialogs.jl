using Test, Gtk4

@testset "ask dialog" begin

main_window = GtkWindow("Dialog example")

r = ask_dialog("May I ask you a question?",main_window; timeout = 0.25)
@test r == false

sleep(1.0)

destroy(main_window)

end

@testset "info dialogs" begin

main_window = GtkWindow("Dialog example")

info_dialog("Here's some information", main_window; timeout = 0.25)
sleep(1.0)
warn_dialog("Here's some alarming information", main_window; timeout = 0.25)
sleep(1.0)
error_dialog("Here's an error", main_window; timeout = 0.25)
sleep(1.0)
GC.gc()
sleep(1.0)
destroy(main_window)

end

@testset "file dialogs" begin

main_window = GtkWindow("Dialog example")

open_dialog("Pick a file to open", main_window; timeout = 0.25)
sleep(1.0)
open_dialog("Pick a file to open", main_window, ["*.png"]; timeout = 0.25)
sleep(1.0)

save_dialog("Pick a filename", main_window; timeout = 0.25)

sleep(1.0)

color_dialog("What is your favorite color?", main_window; timeout = 0.25)

sleep(1.0)

input_dialog("What is the meaning of life, the universe, and everything?", "42", (("Cancel", 0), ("Accept", 1)), main_window; timeout = 0.25)

sleep(1.0)

GC.gc() # ensure GtkDialog is really gone before main_window

destroy(main_window)

end

@testset "File Chooser" begin
    dlg = GtkFileChooserDialog("Select file", nothing, Gtk4.FileChooserAction_OPEN,
                            (("_Cancel", Gtk4.ResponseType_CANCEL),
                             ("_Open", Gtk4.ResponseType_ACCEPT)))
    destroy(dlg)
end

@testset "FileFilter" begin
emptyfilter = GtkFileFilter()
@test get_gtk_property(emptyfilter, "name") === nothing
fname = "test.csv"
fdisplay = "test.csv"
fmime = "text/csv"
csvfilter1 = GtkFileFilter("*.csv")
@test csvfilter1.name == "*.csv"

csvfilter2 = GtkFileFilter("*.csv"; name = "Comma Separated Format")
@test csvfilter2.name == "Comma Separated Format"

csvfilter3 = GtkFileFilter("", "text/csv")
@test csvfilter3.name == "text/csv"

csvfilter4 = GtkFileFilter("*.csv", "text/csv")
# Pattern takes precedence over mime-type, causing mime-type to be ignored
@test csvfilter4.name == "*.csv"
end

