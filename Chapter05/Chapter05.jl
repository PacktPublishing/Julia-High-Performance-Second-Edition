# # Chapter 5

WORD_SIZE

bitstring(3)

bitstring(-3)

isbitstype(Int64)

isbitstype(String)


myadd(x, y) = x + y
@code_native myadd(1,2)


typemax(Int64)


bitstring(typemax(Int32))


typemin(Int64)

bitstring(typemin(Int32))


9223372036854775806 + 1

9223372036854775806 + 1 + 1

2^64

2^65

# ##BigInt

big(9223372036854775806) + 1 + 1

big(2)^64

# ## Floating Point

bitstring(2.5)
bitstring(-2.5)

function floatbits(x::Float64)
   b = bitstring(x)
   b[1:1]*"|"*b[2:12]*"|"*b[13:end]
end

floatbits(2.5)

floatbits(-2.5)


0.1 > 1//10


Rational(0.1)

float(big(Rational(0.1)))

bitstring(0.10000000000000001) == bitstring(0.1)

eps(0.1)

nextfloat(0.1)

floatbits(0.1)

floatbits(nextfloat(0.1))


# ##Unchecked conversions

UInt64(1)
UInt32(4294967297)
4294967297 % UInt32
@btime UInt32(1)
@btime 1 % UInt32


# ## FastMath

function sum_diff(x)
    n = length(x); d = 1/(n-1)
    s = zero(eltype(x))
    s = s +  (x[2] - x[1]) / d
    for i = 2:length(x)-1
        s =  s + (x[i+1] - x[i+1]) / (2*d)
    end
    s = s + (x[n] - x[n-1])/d
end

function sum_diff_fast(x)
    n=length(x); d = 1/(n-1)
    s = zero(eltype(x))
    @fastmath s = s +  (x[2] - x[1]) / d
    @fastmath for i = 2:n-1
        s =  s + (x[i+1] - x[i+1]) / (2*d)
    end
    @fastmath s = s + (x[n] - x[n-1])/d
end

t=rand(2000);
@btime sum_diff($t)
@btime sum_diff_fast($t)

macroexpand(Main, :(@fastmath a + b / c))

# ## KBN Summation

sum([1 1e-100 -1])

using KahanSummation

sum_kbn([1 1e-100 -1])


t=[1, -1, 1e-100];

@btime sum($t)


@btime sum_kbn($t)

# ## Subnormal numbers

issubnormal(1.0)

issubnormal(1.0e-308)

3e-308 - 3.001e-308

issubnormal(3e-308 - 3.001e-308)

set_zero_subnormals(true)


3e-308 - 3.001e-308

3e-308 == 3.001e-308

get_zero_subnormals()

function timestep( b, a, dt )
    n = length(b)
    b[1] = 1
    two = eltype(b)(2)
    for i=2:n-1
        b[i] = a[i] + (a[i-1] - two*a[i] + a[i+1]) * dt
    end
    b[n] = 0
end

function heatflow( a, nstep )
    b = similar(a)
    o = eltype(a)(0.1)
    for t=1:div(nstep,2)
        timestep(b,a,o)
        timestep(a,b,o)
    end
end

set_zero_subnormals(false)

t=rand(1000);

@btime heatflow($t, 1000)

set_zero_subnormals(true)

@btime heatflow($t, 1000)
