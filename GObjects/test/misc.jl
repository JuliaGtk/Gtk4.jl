using GObjects, Base64
using Test

# GBytes is an opaque GBoxed struct

@testset "bytes" begin

f=GObjects.G_.MappedFile_new("test.ini",false)
@test isa(f,GObjects.GBoxed)

b=GObjects.G_.get_bytes(f)
@test isa(b,GBytes)

a=zeros(UInt8,100)
b2=GObjects.G_.Bytes_new(a)

@test GObjects.G_.get_size(b2) == 100

d=GObjects.G_.get_data(b2)

end

@testset "misc" begin
    # test some of the more complicated GI-generated methods
    
    io = IOBuffer();
    iob64_encode = Base64EncodePipe(io);
    write(iob64_encode, "Hello!")
    close(iob64_encode);
    str = String(take!(io))

    d = GObjects.G_.base64_decode(str) # transfer full, returns array with a specified length
    @test String(d) == "Hello!"

    
end
