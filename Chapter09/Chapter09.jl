using BenchmarkTools

versioninfo(verbose=true)

# ## HWloc
using Pkg
Pkg.add("Hwloc")

using Hwloc
Hwloc.num_physical_cores()


# ##Starting Threads

using Base.Threads
nthreads()

threadid()

a=zeros(4)
for i in 1:nthreads()
     a[threadid()] = threadid()
end
a

# ## The @Threads macro
    @threads for i in 1:nthreads()
               a[threadid()] = threadid()
           end


# ### Prefix sum

function prefix_threads!(y)
    l=length(y)
    k=ceil(Int, log2(l))
    for j=1:k
        @threads for i=2^j:2^j:min(l, 2^k)
            @inbounds y[i] = y[i-2^(j-1)] + y[i]
        end
    end
    for j=(k-1):-1:1
        @threads for i=3*2^(j-1):2^j:min(l, 2^k)
            @inbounds y[i] = y[i-2^(j-1)] + y[i]
        end
    end
    y
end

# # Thread Safety

# ## Monte Carlo
using Random
function darts_in_circle(n, rng=Random.GLOBAL_RNG)
   inside = 0
   for i in 1:n
      if rand(rng)^2 + rand(rng)^2 < 1
         inside += 1
      end
   end
 return inside
end

function pi_serial(n)
    return 4 * darts_in_circle(n) / n
end

using Base.Threads

const rnglist = [MersenneTwister() for i in 1:nthreads()];

function pi_threads(n, loops)
   inside = zeros(Int, loops)
   @threads for i in 1:loops
      rng = rnglist[threadid()]
      inside[threadid()] = darts_in_circle(n, rng)
   end
   return 4 * sum(inside) / (n*loops)
end

pi_threads(2_500_000, 4)

 @btime pi_serial(10_000_000)

 @btime pi_threads(2_500_000, 4)

 # ## Atomics

 function sum_thread_base(x)
   r = zero(eltype(x))
   @threads for i in eachindex(x)
      @inbounds r += x[i]
   end
   return r
end

a=rand(10_000_000);

@btime sum($a)

@btime sum_thread_base($a)

function sum_thread_atomic(x)
   r = Atomic{eltype(x)}(zero(eltype(x)))
   @threads for i in eachindex(x)
      @inbounds atomic_add!(r, x[i])
   end
  return r[]
end


 @btime sum_thread_atomic($a)


 function sum_thread_split(A)
   r = Atomic{eltype(A)}(zero(eltype(A)))
   len, rem = divrem(length(A), nthreads())
   #Split the array equally among the threads
   @threads for t in 1:nthreads()
      r[] = zero(eltype(A))
      @simd for i in (1:len) .+ (t-1)*len
         @inbounds r[] += A[i]
      end
      atomic_add!(r, r[])
    end
   result = r[]
   #process up the remaining data
   @simd for i in length(A)-rem+1:length(A)
      @inbounds result += A[i]
   end
   return result
end

@btime sum_thread_split($a)

@btime sum_thread_split($a)

# ## Synchronisation primitives

const f = open(tempname(), "a+")

const mt = Base.Threads.Mutex();

@threads for i in 1:50
     r = pi_serial(10_000_000)
     lock(mt)
     write(f, "From $(threadid()), pi = $r\n")
     unlock(mt)
end


close(f)


const s = Base.Semaphore(2);
@threads for i in 1:nthreads()
   Base.acquire(s)
   r = pi_serial(10_000_000)
   Core.println("Calculated pi = $r in Thread $(threadid())")
   Base.release(s)
end

# # Threaded libraries

a = rand(1000, 1000);

b = rand(1000, 1000);

@btime $a*$b;

# ## Oversubscriptions

function matmul_serial(x)
   first_num = zeros(length(x))
   for i in eachindex(x)
      @inbounds first_num[i] = (x[i]'*x[i])[1]
   end
   return first_num
end


function matmul_thread(x)
   first_num = zeros(length(x))
   @threads for i in eachindex(x)
      @inbounds first_num[i] = (x[i]'*x[i])[1]
   end
   return first_num
end

m = [rand(1000, 1000) for _ in 1:10];

@btime matmul_serial(m);

@btime matmul_thread(m);

using LinearAlgebra
BLAS.set_num_threads(1)

@btime matmul_thread(m);
