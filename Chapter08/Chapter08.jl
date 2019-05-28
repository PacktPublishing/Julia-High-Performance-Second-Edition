using BenchmarkTools

for i in 1:5
    sleep(1)
end

@time for i in 1:5
    sleep(1)
end

@time for i in 1:5
    @async sleep(1)
end


@time @sync for i in 1:5
    @async sleep(1)
end

@time for i in 1:50
    sin.(rand(1000, 1000))
end

@time @sync for i in 1:50
    @async sin.(rand(1000, 1000))
end

@time @sync for i in 1:5
    @async ccall(("sleep", :libc), Cint, (Cint, ), 1)
end

# ## Task Lifecycle

t=Task(()->println("Hello from tasks"))

schedule(t)

istaskstarted(t)

schedule(t)

istaskdone(t)

istaskstarted(t)

current_task()

t == current_task()

# ## Task local storage

task_local_storage("x", 1)

task_local_storage("x") == 1

# # Communicating between tasks

c = Channel{Int}(10)

function producer(c::Channel)
   put!(c, "start")
   for n=1:4
      put!(c, 2n)
   end
   put!(c, "stop")
end

chnl = Channel(producer)

take!(chnl)
take!(chnl)
take!(chnl)
take!(chnl)
take!(chnl)
take!(chnl)

# ## Task Iteration

chnl = Channel(producer)
for i in chnl
    @show i
end

function consume(c)
   println("Starting Channel iteration")
   for i in c
       println("Got $i from Channel")
   end
   println("Channel iteration is complete")
end

chnl = Channel(1)

@async consume(chnl)

put!(chnl, 1)

put!(chnl, 2)

close(chnl)

using Pkg
Pkg.add("Mux")

using Mux
@app basicapp = (
         Mux.defaults,
         page("/", respond("<h1>Hello World!</h1>")),
         Mux.notfound())

serve(basicapp; reuseaddr=true)
