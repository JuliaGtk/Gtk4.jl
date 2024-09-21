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
GC.gc()
sleep(1.0)
close(main_window)

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

input_dialog("Whadya know?", "Not much, you?", main_window; timeout = 0.25)

sleep(1.0)

GC.gc() # ensure GtkDialog is really gone before main_window

close(main_window)

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

@testset "New dialogs" begin
main_window = GtkWindow("New dialog example")
fd=GtkFileDialog()

c=GCancellable()
save(fd, main_window, c) do dlg, resobj
    try
        x=save_path(dlg, resobj)
    catch e
        if !isa(e, Gtk4.GLib.GErrorException)
            rethrow(e)
        end
    end
end
sleep(1.0)
cancel(c)

c=GCancellable()
open_file(fd, main_window, c) do dlg, resobj
    try
        x=open_path(dlg, resobj)
    catch e
        if !isa(e, Gtk4.GLib.GErrorException)
            rethrow(e)
        end
    end
end
sleep(1.0)
cancel(c)

c=GCancellable()
select_folder(fd, main_window, c) do dlg, resobj
    try
        x=select_folder_path(dlg, resobj)
    catch e
        if !isa(e, Gtk4.GLib.GErrorException)
            rethrow(e)
        end
    end
end
sleep(1.0)
cancel(c)

c=GCancellable()
open_multiple(fd, main_window, c) do dlg, resobj
    try
        x=open_paths(dlg, resobj)
    catch e
        if !isa(e, Gtk4.GLib.GErrorException)
            rethrow(e)
        end
    end
end
sleep(1.0)
cancel(c)

c=GCancellable()
select_multiple_folders(fd, main_window, c) do dlg, resobj
    try
        x=select_multiple_folder_paths(dlg, resobj)
    catch e
        if !isa(e, Gtk4.GLib.GErrorException)
            rethrow(e)
        end
    end
end
sleep(1.0)
cancel(c)


sleep(2.0)

close(main_window)
end
