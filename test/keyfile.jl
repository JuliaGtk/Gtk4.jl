using Gtk4.GLib
using Test

# GKeyFile is an opaque struct that is a GBoxed and has methods that take and
# return arrays.

@testset "keyfile" begin

for i=1:1
    kf=GLib.KeyFile()

    @test isa(kf,GLib.GBoxed)

    GLib.set_boolean(kf,"group","bool",true)
    @test GLib.get_boolean(kf,"group","bool")==true

    GLib.set_integer(kf,"group","myint",3)
    @test GLib.get_integer(kf,"group","myint")==3

    GLib.set_double(kf,"group","blah",3.44)
    GLib.set_double(kf,"group","blah2",9.44)
    GLib.set_double(kf,"group2","blah3",9)

    GLib.set_string(kf,"group","desc","A description")
    @test GLib.get_string(kf,"group","desc")=="A description"

    @test GLib.get_double(kf,"group","blah")==3.44
    @test GLib.get_double(kf,"group","blah2")==9.44
    @test GLib.get_double(kf,"group2","blah3")==9

    @test_throws ErrorException GLib.get_double(kf,"group3","blah")==0.0

    # test set_double_list, set_integer_list, etc. with perfectly prepared inputs
    bool_list = convert(Vector{Int32},[true,false,false,true])
    GLib.set_boolean_list(kf,"group","bool_list",bool_list)
    @test bool_list == GLib.get_boolean_list(kf,"group","bool_list")

    int_list = convert(Vector{Int32},[12,13,14,5])
    GLib.set_integer_list(kf,"group","integer_list",int_list)
    @test GLib.get_integer_list(kf,"group","integer_list")==int_list

    double_list = [3.4,6.3,3.2,8.9]
    GLib.set_double_list(kf,"group","double_list",double_list)
    @test GLib.get_double_list(kf,"group","double_list")==double_list

    string_list = ["alpha","beta","gamma"]
    GLib.set_string_list(kf,"group","string_list",string_list)
    @test GLib.get_string_list(kf,"group","string_list")==string_list

    # test set_double_list, set_integer_list, etc. with inputs that need conversion
    bool_list = [true,false,false,true]
    GLib.set_boolean_list(kf,"group","bool_list2",bool_list)
    @test bool_list == GLib.get_boolean_list(kf,"group","bool_list2")

    int_list = [12,13,14,5]
    GLib.set_integer_list(kf,"group","integer_list2",int_list)
    @test GLib.get_integer_list(kf,"group","integer_list2")==int_list

    double_list = [3,6,3,8]
    GLib.set_double_list(kf,"group","double_list2",double_list)
    @test GLib.get_double_list(kf,"group","double_list2")==double_list

    success=GLib.save_to_file(kf,"test.ini")
    @test success
end

kf=GLib.KeyFile()
success=GLib.load_from_file(kf,"test.ini",GLib.Constants.KeyFileFlags.NONE)

@test success

end
