using Gtk4.GLib
using Test

# GKeyFile is an opaque struct that is a GBoxed and has methods that take and
# return arrays.

@testset "keyfile" begin

for i=1:1
    kf=GLib.G_.KeyFile_new()

    @test isa(kf,GLib.GBoxed)

    GLib.G_.set_boolean(kf,"group","bool",true)
    @test GLib.G_.get_boolean(kf,"group","bool")==true

    GLib.G_.set_integer(kf,"group","myint",3)
    @test GLib.G_.get_integer(kf,"group","myint")==3

    GLib.G_.set_double(kf,"group","blah",3.44)
    GLib.G_.set_double(kf,"group","blah2",9.44)
    GLib.G_.set_double(kf,"group2","blah3",9)

    GLib.G_.set_string(kf,"group","desc","A description")
    @test GLib.G_.get_string(kf,"group","desc")=="A description"

    @test GLib.G_.get_double(kf,"group","blah")==3.44
    @test GLib.G_.get_double(kf,"group","blah2")==9.44
    @test GLib.G_.get_double(kf,"group2","blah3")==9

    @test_throws ErrorException GLib.G_.get_double(kf,"group3","blah")

    # test set_double_list, set_integer_list, etc. with perfectly prepared inputs
    bool_list = convert(Vector{Int32},[true,false,false,true])
    GLib.G_.set_boolean_list(kf,"group","bool_list",bool_list)
    @test bool_list == GLib.G_.get_boolean_list(kf,"group","bool_list")

    int_list = convert(Vector{Int32},[12,13,14,5])
    GLib.G_.set_integer_list(kf,"group","integer_list",int_list)
    @test GLib.G_.get_integer_list(kf,"group","integer_list")==int_list

    double_list = [3.4,6.3,3.2,8.9]
    GLib.G_.set_double_list(kf,"group","double_list",double_list)
    @test GLib.G_.get_double_list(kf,"group","double_list")==double_list

    string_list = ["alpha","beta","gamma"]
    GLib.G_.set_string_list(kf,"group","string_list",string_list)
    @test GLib.G_.get_string_list(kf,"group","string_list")==string_list

    # test set_double_list, set_integer_list, etc. with inputs that need conversion
    bool_list = [true,false,false,true]
    GLib.G_.set_boolean_list(kf,"group","bool_list2",bool_list)
    @test bool_list == GLib.G_.get_boolean_list(kf,"group","bool_list2")

    int_list = [12,13,14,5]
    GLib.G_.set_integer_list(kf,"group","integer_list2",int_list)
    @test GLib.G_.get_integer_list(kf,"group","integer_list2")==int_list

    double_list = [3,6,3,8]
    GLib.G_.set_double_list(kf,"group","double_list2",double_list)
    @test GLib.G_.get_double_list(kf,"group","double_list2")==double_list

    success=GLib.G_.save_to_file(kf,"test.ini")
    @test success
end

kf=GLib.G_.KeyFile_new()
success=GLib.G_.load_from_file(kf,"test.ini",GLib.KeyFileFlags_NONE)

@test success

end
