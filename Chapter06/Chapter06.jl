

# Chapter 6

using BenchmarkTools

# #Array Internals

# ## Column wise storage

function col_iter(x)
    s=zero(eltype(x))
    for i = 1:size(x, 2)
       for j = 1:size(x, 1)
          s = s + x[j, i] ^ 2
          x[j, i] = s
       end
    end
end

function row_iter(x)
   s=zero(eltype(x))
   for i = 1:size(x, 1)
      for j = 1:size(x, 2)
       s = s + x[i, j] ^ 2
         x[i, j] = s
      end
   end
end

a = rand(1000, 1000);

@btime col_iter($a)

@btime row_iter($a)

# ### Adjoints

a = rand(1000, 1000);

b=a'

@btime col_iter($b)

@btime row_iter($b)

# ## Array initialization

a = fill(1, 4, 4)

@btime fill(1, 1000, 1000);

@btime Array{Int64}(undef, 1000, 1000);

a=Array{Int}(undef, 2, 2)

b=Array{String}(undef, 2, 2)

b[1,1]  # Will throw UndefRefError


 ## Bounds Checking

 function prefix_bounds(a, b)
      for i in 2:size(a, 1)
            a[i] = b[i-1] + b[i]
      end
end


function prefix_inbounds(a, b)
    @inbounds for i in 2:size(a, 1)
         a[i] = b[i-1] + b[i]
    end
end

a=zeros(Float64, 1000);

b=rand(1000);

@btime prefix_bounds($a, $b)

@btime prefix_inbounds($a, $b)

# # In place operations

function xpow(x)
   return [x x^2 x^3 x^4]
end

function xpow_loop(n)
    s = 0
    for i = 1:n
      s = s + xpow(i)[2]
    end
   return s
end

@btime xpow_loop($1000000)

# ## Preallocating function output

function xpow!(result::Array{Int, 1}, x)
    @assert length(result) == 4
    result[1] = x
    result[2] = x^2
    result[3] = x^3
    result[4] = x^4
end

function xpow_loop_noalloc(n)
    r = [0, 0, 0, 0]
    s = 0
    for i = 1:n
       xpow!(r, i)
       s = s + r[2]
    end
    s
end
@btime xpow_loop_noalloc($1000000)

@time xpow_loop(1_000_000)

@time xpow_loop_noalloc(1_000_000)

@btime sort(a);
@btime sort!(a);

# ## Mutating FUnctions

 @btime sort(a);

 @btime sort!(a);

# # Broadcasting

a=collect(1:4);

sqrt.(a)

b=reshape( 1:8, 4, 2)

b .+ a

a = collect(1:10);

b = fill(0.0, 10);

b .= cos.(sin.(A))

@time b .= cos.(sin.(a));

@btime c = cos.(sin.(a));




# # Array Views

function sum_vector(x::Array{Float64, 1})
   s = zero(eltype(x))
   for i in 1:length(x)
      s = s + x[i]
   end
   return s
end

function sum_cols_matrix(x::Array{Float64, 2})
   num_cols = size(x, 2)
   s = zeros(num_cols)
   for i = 1:num_cols
     s[i] = sum_vector(x[:, i])
   end
   return s
end

@benchmark sum_cols_matrix($a)

function sum_vector(x::AbstractArray)
   s = zero(eltype(x))
   for i in 1:length(x)
      s = s + x[i]
   end
   return s
end

function sum_cols_matrix_views(x::Array{Float64, 2})
   num_cols = size(x, 2); num_rows = size(x, 1)
   s = zeros(num_cols)
   for i = 1:num_cols
     s[i] = sum_vector(@view(x[:, i]))
   end
   return s
end

@benchmark sum_cols_matrix_views($a)


# # SIMD Parallelization

function sum_vectors!(x, y, z)
    n = length(x)
    for i in 1:n
        x[i] = y[i] + z[i]
    end
end


function sum_vectors_simd!(x, y, z)
    n = length(x)
    @inbounds @simd for i in 1:n
          x[i] = y[i] + z[i]
    end
end

a=zeros(Float32, 1_000_000);
b= rand(Float32, 1_000_000);
c= rand(Float32, 1_000_000);


@btime sum_vectors!($a, $b, $c)

@btime sum_vectors_simd!($a, $b, $c)

@code_llvm sum_vectors_simd!(a, b, c)

@code_native sum_vectors_simd!(a, b, c)

# ## SIMD.jl

using Pkg
Pkg.add("SIMD.jl")

using SIMD

a=Vec{4, Float64}((1.0, 2.0, 3.0, 4.0))

@btime sum($a)

@code_native sum(a)

b=[1.,2.,3.,4.]

function naive_sum(x::Vector{Float64})
  s = 0.0
  for i=1:length(x)
     s=s+x[i]
  end
  return s
end

@btime naive_sum($b)

function vadd!(xs::Vector{T}, ys::Vector{T}, ::Type{Vec{N,T}}) where {N, T}
    @assert length(ys) == length(xs)
    @assert length(xs) % N == 0
    lane = VecRange{N}(0)
    @inbounds for i in 1:N:length(xs)
        xs[lane + i] += ys[lane + i]
    end
end

# # Specialised Array Types

# ## Static Arrays

using Pkg
Pkg.add("StaticArrays")

using StaticArrays
a=SVector(1, 2, 3, 4)
b = @SVector [3, 4, 5, 6

c=[1,2,3,4];

@btime $c*$c'

 @btime $a*$a'

 @btime $(Ref(a))[] * $(Ref(a'))[]

# ## Struct Of Arrays

using Pkg
Pkg.add("StructArrays")

a=Complex.(rand(1000000), rand(1000000))

b = StructArray(a)

c = StructArray(i + 2*i*im for i in 1:10)

d = StructArray{ComplexF64}(undef, 10)

using Random
Random.rand!(d)

d.re

d[5]

typeof(d[5])

function accum(x, z)
   s = zero(eltype(x))
   @simd for i in 1:length(x)
       @inbounds s += x[i] * z
   end
   s
end

@btime accum($a, 1.5 + 2.5im)

@btime accum($b, 1.5 + 2.5im)

# # Yeppp

using Pkg
Pkg.add("Yeppp")

using Yeppp
a=rand(1_000_000);

@btime log.($a);

@btime Yeppp.log($a)

@btime Yeppp.log!($a)

# # Generic array functions

function mysum_linear(a::AbstractArray)
    s=zero(eltype(a))
    for i in 1:length(a)
        s=s + a[i]
    end
    return s
end

mysum_linear(1:1000000)

mysum_linear(reshape(1:1000000, 100, 100, 100))

mysum_linear(reshape(1:1000000, 1000, 1000))

mysum_linear(@view reshape(1:1000000, 1000, 1000)[1:500, 1:500] )

@btime mysum_linear(reshape(1:1000000, 1000, 1000))

@btime mysum_linear(@view reshape(1:1000000, 1000, 1000)[1:500, 1:500] )

function mysum_in(a::AbstractArray)
   s = zero(eltype(a))
   for i in a
      s = s + i
   end
end

@btime mysum_in(@view reshape(1:1000000, 1000, 1000)[1:500, 1:500] )

function mysum_eachindex(a::AbstractArray)
    s = zero(eltype(a))
    for i in eachindex(a)
        s = s + a[i]
    end
end 

@btime mysum_eachindex(@view reshape(1:1000000, 1000, 1000)[1:500, 1:500] )
