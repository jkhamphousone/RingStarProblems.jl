@with_kw mutable struct Instance
    n::Int
    V::UnitRange{Int} = 1:n
    tildeV::Vector{Int} = 2:n
    F::Float64
    o::Vector{Float64}
    @assert length(o) == n
    α::Float64
    c::Dict{Tuple{Int,Int},Float64}
    c′::Dict{Tuple{Int,Int},Float64}
    d::Dict{Tuple{Int,Int},Float64}
    d′::Dict{Tuple{Int,Int},Float64}
    x::Vector{Float64}
    y::Vector{Float64}
end

function print_inst(inst::Instance, pars)
    V = inst.V
    str = "F = $(inst.F)\ntildeV = $(inst.tildeV)\n"
    str *= "opening hub costs\n"
    for i in V
        str *= "$i:$(inst.o[i]) "
    end
    str *= "\nc = \n      "
    rpad_value = 4
    for i in V
        str *= "$(rpad(i,rpad_value)) "
    end
    str *= '\n'
    for i in V
        for j in 1:inst.n
            if j == 1
                str *= "$(rpad(i,rpad_value))"
            end
            if i < j
                str *= "$(lpad(Int(inst.c[i,j]),rpad_value)) "
            else
                str *= rpad("  .  ", rpad_value)
            end
        end
        str *= '\n'
    end
    str *= "\nd = \n "
    for i in V
        str *= "$(rpad(i,rpad_value)) "
    end
    str *= '\n'
    for i in V
        for j in V
            if j == 1
                str *= "$(rpad(i,rpad_value ))"
            end
            if i != j
                str *= "$(lpad(Int(inst.d[i,j]),rpad_value)) "
            else
                str *= rpad("  . ", rpad_value)
            end
        end
        str *= '\n'
    end
    str *= "\nc'=$(pars.backup_factor)c and d'=$(pars.backup_factor)d"

    open("./debug/instance_$(today()).txt", "w") do io
        write(io, str)
    end
end

function create_instance_robust_journal_article(filename, α, pars)
    random_filepath = "./instances/Instances_journal_article/RAND/$filename.dat"
    if pars.n_rand > 0 && !isfile(random_filepath)
        n = pars.n_rand
        data = [1:1000 rand(1:1000, 1000) rand(1:1000, 1000)]

        V = 1:n
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]

        if α == 0
            error("Please define α")
        end
        x_coors = data[1:n, 2]
        y_coors = data[1:n, 3]
        @assert pars.r_ij == "l_ij"
        c = Dict((e[1], e[2])
        =>
            ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]])) for e in E)


        d = Dict((a[1], a[2]) => a[1] == a[2] ? 0 : round(1 / rand(Uniform(n / 2, 3n / 2)), digits=5) for a in A)
        if pars.s_ij == "l_ij"
            d = Dict((a[1], a[2])
            =>
                ceil_labbe(distance([x_coors[a[1]], y_coors[a[1]]], [x_coors[a[2]], y_coors[a[2]]])) for a in A)
        end
        for i in 2:n
            c[i, n+1] = c[1, i]
        end
        c[1, n+1] = 0

        o = zeros(Float64, n)
        if pars.o_i == "1:1000"
            o = rand(1:1000, n)
        elseif pars.o_i == "1"
            o = ones(Float64, n)
        end

        open(random_filepath, "w") do f
            println(f, "$n 0.0 $α")
            for i in 1:n
                println(f, "$i $(x_coors[i]) $(y_coors[i])")
            end
            println(f, "opening costs")
            for i in 1:n
                print(f, o[i], " ")
            end
            println(f)
            println(f, "star costs")
            for i in 1:n
                for j in 1:n
                    print(f, s[i, j], " ")
                end
                println(f)
            end
        end
        c′ = Dict{Tuple{Int,Int},Float64}()
        d′ = Dict{Tuple{Int,Int},Float64}()
        for kv in c
            c′[kv[1]] = c[kv[1]] * pars.backup_factor
        end
        for kv in d
            d′[kv[1]] = d[kv[1]] * pars.backup_factor
        end
        return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)

    elseif pars.n_rand == 0

        data = readdlm(filename)
        n = Int64(data[4, 2])
        @assert α != 0

        V = 1:n
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]



        o = zeros(Float64, n)
        if pars.o_i == "1:1000"
            o = rand(1:1000, n)
        elseif pars.o_i == "1"
            o = ones(Float64, n)
        end

        if filename[end-12:end] == "brazil58.tsp2"
            c = Dict((e[1], e[2])
            =>
                ceil_labbe(data[7+e[1], e[2]-e[1]] * α) for e in E)
            d = Dict((a[1], a[2])
            =>
                a[1] == a[2] ? 0.0 : (a[1] < a[2] ?
                 ceil_labbe(data[7+a[1], a[2]-a[1]] * (10 - α)) :
                 ceil_labbe(data[7+a[2], a[1]-a[2]] * (10 - α))) for a in A)

            for i in 2:n
                c[i, n+1] = c[1, i]
            end
            c[1, n+1] = 0
            c′ = Dict{Tuple{Int,Int},Float64}()
            d′ = Dict{Tuple{Int,Int},Float64}()
            for kv in c
                c′[kv[1]] = c[kv[1]] * pars.backup_factor
            end
            for kv in d
                d′[kv[1]] = d[kv[1]] * pars.backup_factor
            end
            return Instance(n, V, 2:Int(ceil(n * pars.tildeV / 100)), pars.F, o, α, c, c′, d, d′, zeros(Int, n), zeros(Int, n))
        else
            shift_n = 0
            if filename[end-7:end] == "120.tsp2"
                shift_n = 414 - 7
            end
            x_coors = data[7+shift_n:n+shift_n+6, 2]
            y_coors = data[7+shift_n:n+shift_n+6, 3]
            c = Dict((e[1], e[2])
            =>
                ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]]) * (α)) for e in E)


            for i in 2:n
                c[i, n+1] = c[1, i]
            end
            c[1, n+1] = 0


            d = Dict((a[1], a[2])
            =>
                ceil_labbe(distance([x_coors[a[1]], y_coors[a[1]]], [x_coors[a[2]], y_coors[a[2]]]) * (10 - α)) for a in A)

            c′ = Dict{Tuple{Int,Int},Float64}()
            d′ = Dict{Tuple{Int,Int},Float64}()
            for kv in c
                c′[kv[1]] = c[kv[1]] * pars.backup_factor
            end
            for kv in d
                d′[kv[1]] = d[kv[1]] * pars.backup_factor
            end
            return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)
        end

    else
        data = readdlm(random_filepath)
        n = Int64(data[1, 1])
        V = 1:n
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]
        x_coors = data[2:n+1, 2]
        y_coors = data[2:n+1, 3]
        o = data[n+3, 1:n]
        @assert pars.r_ij == "l_ij"
        c = Dict((e[1], e[2])
        =>
            ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]])) for e in E)

        for i in 2:n
            c[i, n+1] = c[1, i]
        end
        c[1, n+1] = 0
        d_data = data[n+5:2n+4, 1:n]
        d = Dict((a[1], a[2])
        =>
            d_data[a[1], a[2]] for a in A)
        c′ = Dict{Tuple{Int,Int},Float64}()
        d′ = Dict{Tuple{Int,Int},Float64}()
        for kv in c
            c′[kv[1]] = c[kv[1]] * pars.backup_factor
        end
        for kv in d
            d′[kv[1]] = d[kv[1]] * pars.backup_factor
        end
        return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)
    end
end

function create_instance_robust(filename, α, pars)
    random_filepath = "./instances/Instances_random/$(filename[2]).dat"

    if filename[1] == "tiny_instance_7_2"
        tildeV = [4, 5, 6, 7]
    elseif filename[1] in ["random", "RAND_article"]
        tildeV = 2:pars.n_rand
    elseif filename[1] == "tiny_instance_11_inoc2022"
        # WARNING please use α = 2
        tildeV = [2, 4, 5, 6, 7, 8, 9, 10]
    end

    if pars.n_rand > 0 && !isfile(random_filepath)
        n = pars.n_rand
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        data = [1:n rand(1:n, n) rand(1:n, n)]

        V = 1:n
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]

        if α == 0
            error("Please define α")
        end
        x_coors = data[1:n, 2]
        y_coors = data[1:n, 3]
        c = Dict((e[1], e[2])
        =>
            ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]]) * α) for e in E)
        d = Dict((a[1], a[2]) => a[1] == a[2] ? 0 : round(1 / rand(Uniform(n / 2, 3n / 2)), digits=5) for a in A)
        o = Float64[]
        if pars.o_i == "1"
            o = Float64[1.0 for i in 1:n]
        elseif pars.o_i == "random"
            o = Float64[rand(n/2:3n/2) for i in 1:n]
        end

        open(random_filepath, "w") do f
            println(f, "$n 0.0 $α")
            for i in 1:n
                println(f, "$i $(x_coors[i]) $(y_coors[i])")
            end
            println(f, "opening costs")
            for i in 1:n
                print(f, o[i], " ")
            end
            println(f)
            println(f, "star costs")
            for i in 1:n
                for j in 1:n
                    print(f, s[i, j], " ")
                end
                println(f)
            end
        end
        c′ = Dict{Tuple{Int,Int},Float64}()
        d′ = Dict{Tuple{Int,Int},Float64}()
        for kv in c
            c′[kv[1]] = c[kv[1]] * pars.backup_factor
        end
        for kv in d
            d′[kv[1]] = d[kv[1]] * pars.backup_factor
        end
        return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)
    elseif pars.n_rand == 0
        data = readdlm(filename[2])
        n = Int64(data[1, 1])
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        if α == 0
            α = Int64(data[1, 3])
        end
        V = 1:n
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]

        x_coors = data[2:n+1, 2]
        y_coors = data[2:n+1, 3]


        o = Float64[n for i in 1:n]
        c = Dict((e[1], e[2])
        =>
            ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]]) * α) for e in E)
        for i in 2:n
            c[i, n+1] = c[1, i]
        end
        c[1, n+1] = 0
        d = Dict((a[1], a[2])
        =>
            ceil_labbe(distance([x_coors[a[1]], y_coors[a[1]]], [x_coors[a[2]], y_coors[a[2]]])) * (10 - α) for a in A)
  
        c′ = Dict{Tuple{Int,Int},Float64}()
        d′ = Dict{Tuple{Int,Int},Float64}()
        for kv in c
            c′[kv[1]] = c[kv[1]] * pars.backup_factor
        end
        for kv in d
            d′[kv[1]] = d[kv[1]] * pars.backup_factor
        end
        return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)
    else
        data = readdlm(random_filepath)
        @show random_filepath
        n = Int64(data[1, 1])
        tildeV = 2:Int(ceil(n * pars.tildeV / 100))
        if α == 0
            α = Int64(data[1, 3])
        end
        V = 1:n
        E = [(i, j) for i in V, j in V if i < j]
        A = [(i, j) for i in V, j in V]
        Ac = [(i, j) for i in V, j in V if i != j]
        x_coors = data[2:n+1, 2]
        y_coors = data[2:n+1, 3]
        o = data[n+3, 1:n]
        c = Dict((e[1], e[2])
        =>
            ceil_labbe(distance([x_coors[e[1]], y_coors[e[1]]], [x_coors[e[2]], y_coors[e[2]]]) * α) for e in E)

        for i in 2:n
            c[i, n+1] = c[1, i]
        end
        c[1, n+1] = 0
        d_data = data[n+5:2n+4, 1:n]
        d = Dict((a[1], a[2])
        =>
            d_data[a[1], a[2]] for a in A)
        c′ = Dict{Tuple{Int,Int},Float64}()
        d′ = Dict{Tuple{Int,Int},Float64}()
        for kv in c
            c′[kv[1]] = c[kv[1]] * pars.backup_factor
        end
        for kv in d
            d′[kv[1]] = d[kv[1]] * pars.backup_factor
        end
        return Instance(n, V, tildeV, pars.F, o, α, c, c′, d, d′, x_coors, y_coors)
    end
end




function instance_transform(inst, inst_trans)
    if inst_trans == 0
        return inst.c, inst.c, inst.s, 0.0
    end
    V = inst.V
    tildeV = inst.tildeV
    n = inst.n
    offset = sum(minimum(inst.d[i, k] for k in V if k != i) for i in V)
    c = copy(inst.c)
    c′ = copy(inst.c)
    d = copy(inst.d)
    minedgecost = minimum(c[l, h] for l in V, h in V if l < h)
    for i in V
        if i in tildeV
            o[i] -= minimum(inst.d[i, k] for k in V if k != i) - minedgecost
        else
            o[i] -= minimum(inst.d[i, k] for k in V if k != i)
        end
        for j in V
            if i < j
                c[i, j] -= minedgecost
            end
            if j in tildeV && i != j
                d[i, j] -= 0.5minimum(inst.d[i, k] for k in V if k != i)
            elseif i != j
                d[i, j] -= minimum(inst.d[i, k] for k in V if k != i)
            end
        end
    end
    # println("transformation 1")
    # @show s
    return o, c, c′, d, offset
end

function instance_transform_improved(inst, inst_trans)
    if inst_trans <= 1
        return instance_transform(inst, inst_trans)
    end
    n = inst.n
    V = inst.V
    tildeV = inst.tildeV
    offset = zeros(Float64, n)
    ε = zeros(Float64, n)
    o = copy(inst.o)

    r = copy(inst.r)
    r′ = copy(inst.r)
    s = copy(inst.s)

    for i in V
        fst_min = Inf
        snd_min = Inf
        for k in V
            if k in tildeV && k != i && snd_min > s[i, k]
                snd_min = s[i, k]
            elseif k != i && !(k in tildeV) && fst_min > s[i, k]
                fst_min = s[i, k]
            end
        end
        offset[i] = min(fst_min, 2snd_min)

        fst_min = Inf
        snd_min = Inf
        for k in 1:i-1
            if fst_min > r′[k, i]
                fst_min = r′[k, i]
            end
        end
        for k in i+1:n
            if snd_min > r′[i, k]
                snd_min = r′[i, k]
            end
        end
        ε[i] = min(fst_min, snd_min)
    end
    bar_offset = sum(offset)
    for i in V
        o[i] -= offset[i]
        for j in V
            if i < j
                if i in tildeV
                    if j in setdiff(V, tildeV)
                        r[i, j] += 0.5ε[j]
                    else
                        r[i, j] += 0.5(ε[i] + ε[j])
                    end
                elseif j in tildeV
                    r[i, j] += 0.5ε[i]
                end
                r′[i, j] -= 0.5(ε[i] + ε[j])
            end
            if j in setdiff(tildeV, i)
                s[i, j] -= 0.5offset[i]
            elseif j != i
                s[i, j] -= offset[i]
            end
        end
    end


    return o, r, r′, s, bar_offset
end
