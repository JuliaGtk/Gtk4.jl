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

