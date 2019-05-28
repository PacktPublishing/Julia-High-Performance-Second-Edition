# # Chapter 1

# ## Using Types
using BenchmarkTools

# Declare type of function argument
iam(x::Integer) = "an integer"
iam(x::String) = "a string"

function addme(a, b)
  #Declare type of local variable x
  x::Int64 = 2
  #Type of variable y will be inferred
  y = (a+b) / x
  return y
end

iam(1)

iam("1")

iam(1.5)

# ## Multiple Dispatch
sumsqr(x, y) = x^2 + y^2

sumsqr(1, 2)

sumsqr(1.5, 2.5)

sumsqr(1 + 2im , 2 + 3im)

sumsqr(2 + 2im, 2.5)

#Composite Types

struct Pixel
    x::Int64
    y::Int64
    color::Int64
end

p = Pixel(5,5, 100)

p.x = 10;

p.x

# immutable types

mutable struct MPixel
    x::Int64
    y::Int64
    color::Int64
end

p = MPixel(5,5, 100)

p.x=10;

p.x


# TYpe Parameters

struct PPixel{T}
    x::Int64
    y::Int64
    color::T
end

#Type Inference

[x for x=1:5]

# Type Stability

function pos(x)
   if x < 0
      return 0
   else
      return x
   end
end

pos(-1)


pos(-2.5)


pos(2.5)


typeof(pos(2.5))


typeof(pos(-2.5))

function pos_fixed(x)
    if x < 0
        return zero(x)
    else
        return x
    end
end

pos_fixed(-2.4)

pos_fixed(-2)

typeof(pos_fixed(-2.4))

typeof(pos_fixed(-2))

@btime pos(2.5)
@btime pos_fixed(2.5)

@code_warntype pos(2.5)
@code_warntype pos_fixed(2.5)
@code_llvm pos(2.5)
@code_llvm pos_fixed(2.5)

@code_native pos(2.5)
@code_native pos_fixed(2.5)

# Loop variables

function sumsqrtn(n)
    r = 0
    for i = 1:n
        r = r + sqrt(i)
    end
    return r
end


@code_warntype sumsqrtn(5)

function sumsqrtn_fixed(n)
     r = 0.0
     for i = 1:n
         r = r + sqrt(i)
     end
     return r
end

@code_warntype sumsqrtn_fixed(5)

@btime sumsqrtn(1000_000)

@btime sumsqrtn_fixed(1000_000)

#Kernel Methods

function string_zeros(s::AbstractString)
    n=1000_000
    x = s=="Int64" ?
        Vector{Int64}(undef,n) :
        Vector{Float64}(undef, n)
    for i in 1:length(x)
        x[i] = 0
    end
    return x
end

@btime string_zeros("Int64");


function string_zeros_stable(s::AbstractString)
    n = 1000_000
    x = s=="Int64" ?
        Vector{Int64}(undef, n) :
        Vector{Float64}(undef, n)
    return fill_zeros(x)
end

function fill_zeros(x)
    for i in 1:length(x)
        x[i] = 0
    end
    return x
end

@btime string_zeros_stable("Int64");

#Types in storage
## Arrays

a = Int64[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
b = Number[1,2,3,4,5,6,7,8,9,10]

function arr_sumsqr(x::Array{T}) where T <: Number
    r = zero(T)
    for i = 1:length(x)
        r = r + x[i] ^ 2
    end
    return r
end

 @btime arr_sumsqr(a)
 @btime arr_sumsqr(b)

## Composite Types
struct Point
    x
    y
end

struct ConcretePoint
    x::Float64
    y::Float64
end


function sumsqr_points(a)
    s=0.0
    for x in a
        s = s + x.x^2 + x.y^2
    end
    return s
end

p_array = [Point(rand(), rand()) for i in 1:1000_000];
cp_array = [ConcretePoint(rand(), rand()) for i in 1:1000_000];

@btime sumsqr_points(p_array)
@btime sumsqr_points(cp_array)

## Parametric Composite Types

struct PointWithAbstract
    x::AbstractFloat
    y::AbstractFloat
end

struct ParametricPoint{T <: AbstractFloat}
    x::T
    y::T
end

pp_array = [ParametricPoint(rand(), rand()) for i in 1:1000_000];


@btime sumsqr_points(pp_array)
