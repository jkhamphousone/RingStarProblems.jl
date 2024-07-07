import Base.push!
import Base.sort

mutable struct SKB
    K::Float64
    B::Float64
end

const ε = 1e-6


@with_kw mutable struct Fm_Sm
    @deftype Vector{Float64}
    F = Float64[]
    F_scaled = Float64[]
    sKB::Vector{SKB}
    explore_time = Float64[]
    Fm_Sm(F, F_scaled, sKB, explore_time) = new(Float64[F], Float64[F_scaled], SKB[sKB], Float64[round(explore_time, digits=7)])
end

function push!(list_Fm_Sm::Fm_Sm, values::Tuple{Float64,SKB,Float64}, backup_factor::Float64)
    push!(list_Fm_Sm.F, values[1])
    push!(list_Fm_Sm.F_scaled, values[1] * backup_factor)
    push!(list_Fm_Sm.sKB, values[2])
    push!(list_Fm_Sm.explore_time, round(values[3], digits=7))
end


function sort_filter(list_Fm_Sm::Fm_Sm)
    order = sortperm(list_Fm_Sm.F)
    sorted_list_Fm_Sm = deepcopy(list_Fm_Sm)
    sorted_list_Fm_Sm.F = list_Fm_Sm.F[order]
    sorted_list_Fm_Sm.F_scaled = list_Fm_Sm.F_scaled[order]
    sorted_list_Fm_Sm.sKB = list_Fm_Sm.sKB[order]
    sorted_list_Fm_Sm.explore_time = list_Fm_Sm.explore_time[order]


    function deleteat_list_Fm_Sm!(list_Fm_Sm::Fm_Sm, a)
        deleteat!(list_Fm_Sm.F, a)
        deleteat!(list_Fm_Sm.F_scaled, a)
        deleteat!(list_Fm_Sm.sKB, a)
        deleteat!(list_Fm_Sm.explore_time, a)
    end

    deleting = true
    while deleting
        deleting = false
        for i in 1:length(sorted_list_Fm_Sm.F)-1
            if i+1 <= length(sorted_list_Fm_Sm.F)
                @info sorted_list_Fm_Sm.F[i], sorted_list_Fm_Sm.F[i+1]
                @info sorted_list_Fm_Sm.sKB[i].B, sorted_list_Fm_Sm.sKB[i+1].B
                if abs(sorted_list_Fm_Sm.F[i] - sorted_list_Fm_Sm.F[i+1]) < ε
                    println("Deleting... case 1")
                    deleting = true
                    sorted_list_Fm_Sm.sKB[i].B > sorted_list_Fm_Sm.sKB[i+1].B ?
                    deleteat_list_Fm_Sm!(sorted_list_Fm_Sm, i) :
                    deleteat_list_Fm_Sm!(sorted_list_Fm_Sm, i + 1)
                elseif abs(sorted_list_Fm_Sm.sKB[i].B - sorted_list_Fm_Sm.sKB[i+1].B) < ε
                    println("Deleting... case 2")
                    deleting = true
                    sorted_list_Fm_Sm.F[i] > sorted_list_Fm_Sm.F[i+1] ?
                    deleteat_list_Fm_Sm!(sorted_list_Fm_Sm, i) :
                    deleteat_list_Fm_Sm!(sorted_list_Fm_Sm, i + 1)
                end
            end
        end
    end
    return sorted_list_Fm_Sm
end



compute_gS(sKB::SKB, F) = F * sKB.B + sKB.K
compute_gS_scaled(sKB::SKB, F) = round(Float64((F * sKB.B + sKB.K) / 100), digits=7)

compute_gS(list_Fm_Sm, i::Int) = compute_gS(list_Fm_Sm.sKB[i], list_Fm_Sm.F[i])
compute_gS_scaled(list_Fm_Sm, i::Int) = compute_gS_scaled(list_Fm_Sm.sKB[i], list_Fm_Sm.F[i])


function write_tikz_list_Fm_Sm(list_Fm_Sm::Fm_Sm, filename, exploreplustime, ncall_bbc, inst, pars)
    now_folder = Dates.format(Dates.now(), "yyyy-mm-dd")
    n = length(list_Fm_Sm.F)




    str = raw"\documentclass{article}

     \usepackage[top=2cm,bottom=2cm,left=2cm,right=2cm]{geometry}
     \usepackage{amsfonts,amsmath,amssymb}
     \usepackage{color}
     \usepackage{url}
     \usepackage{tikz}
     \usetikzlibrary{patterns,shapes}

     \begin{document}

     \title{Solving RRSP$(F)$ when $F$ belongs to an interval}
     \author{Julien Khamphousone, Fabi\'an Casta\~no, Andr\'e Rossi, Sonia Toubaline}
     \date{"
    str*="$(Dates.today())"
    str*=raw"}
     \maketitle
     "

    str *= "\\def\\F{{"
    for i in 1:n
        str *= "$(round(Float64(list_Fm_Sm.F_scaled[i]),digits=7))"
        str *= ","
    end

    F_end = list_Fm_Sm.F_scaled[end]

    str *= "$(round(Float64(F_end*1.1),digits=7))"
    str *= "}}\n"

    str *= "\\def\\gF{{"
    for i in 1:n
        str *= "$(compute_gS_scaled(list_Fm_Sm,i))"
        str *= ","
    end

    str *= "$(round(Float64(list_Fm_Sm.sKB[end].K + list_Fm_Sm.sKB[end].B *F_end),digits=7))"
    str *= "}}\n"



    # str *= raw"\begin{figure}[ht!]
    # \begin{center}
    # \begin{tikzpicture}[scale=.2cm, xscale=2cm]
    # \tikzset{axe/.style={->,>=stealth,draw,color=black}}
    # \tikzset{g/.style={draw,color=red,line width=1pt}}
    # \tikzset{convX/.style={fill=yellow}}
    # \draw[axe](0,0) -- ("

    # str *= "$(round(Float64(list_Fm_Sm.F_scaled[end]/4),digits=7))"

    # str *= raw",0);
    #  \draw[axe](0,0) -- (0,"

    # str *= "$(compute_gS_scaled(list_Fm_Sm,n)*1.1)"

    # str *= ");"


    # for i in 0:n-1
    #     str *= "\\draw (\\F[$i],0) -- (\\F[$i],-.2);
    #     \\draw (\\F[$i],0pt) -- (\\F[$i],-1pt) node[anchor=north,inner sep = 8pt] {\\scriptsize{\$F_$(i)\$}};
    #     \\draw[thick, dashed](\\F[$i],0) -- (\\F[$i], \\gF[$i]);\n"
    # end

    # for i in 0:n-1
    #     str *= "\\draw (0, \\gF[$i]) -- (-.2, \\gF[$i]);
    #     \\draw (0, \\gF[$i]) -- (-1pt, \\gF[$i]) node[anchor=east,inner sep = 8pt] {\\scriptsize{\$g(F_$(i))\$}};
    #     \\draw[thick, dashed](0,\\gF[$i]) -- (\\F[$i],\\gF[$i]);\n"
    # end

    # str *= "\\node (F) at ("

    # str *= "$(round(Float64(list_Fm_Sm.F_scaled[end]/4+2),digits=7))"

    # str *= ",2){}; \\draw(F) node{\$F\$};
    # \\node (g) at (2,"

    # str *= "$(compute_gS_scaled(list_Fm_Sm,length(list_Fm_Sm.F))*1.1)"

    # str *= "){}; \\draw(g) node{\$g(F)\$};
    # % Lines\n"

    # str *= "\\draw[g] "
    # for i in 0:n-2
    #     str *= "(\\F[$i], \\gF[$i]) -- "
    # end
    # str *= "(\\F[$(n-1)], \\gF[$(n-1)]);"

    # str *= raw"% Integer points
    # %\draw[fill=black] (1,2) circle(.05);
    # \end{tikzpicture}
    # \end{center}
    # \vspace*{-2eM}
    # \caption{$g(F)$ for the "
    # str*="$(replace(filename,"_"=>" "))"
    # str*=raw" instance}\label{fig:1}
    # \end{figure}"

    str *= raw"
    Here are the $F$, $B$ and $K$ values rounded at 5 digits:

\begin{itemize}
	\item  $F = ["

    for i in 1:n
        str *= "$(round(Float64(list_Fm_Sm.F[i]),digits=7))"
        if i != n
            str *= ","
        end
    end

    str *= raw"]$
 \item $B = ["

    for i in 1:n
        str *= "$(round(Float64(list_Fm_Sm.sKB[i].B),digits=7))"
        if i != n
            str *= ","
        end
    end

    str *= raw"]$
 \item  $K = ["

    for i in 1:n
        str *= "$(round(Float64(list_Fm_Sm.sKB[i].K),digits=7))"
        if i != n
            str *= ","
        end
    end
    str *= raw"]$"
    str *= raw"\item Total execution time is: "
    str *= "$(round(time()-exploreplustime,digits=2))s"
    if pars.solve_mod == "Ben"
        str *= raw"\item Number of times BBC is called: "
    else
        str *= raw"\item Number of times ILP is called: "
    end
    str *= "$(length(ncall_bbc))"
    str *= raw"\end{itemize}"



    str *= raw"\end{document}"


    mkpath(eval(@__DIR__) * "/results/tikz/$now_folder/")
    open(eval(@__DIR__) * "/results/tikz/$now_folder/$(filename)_α=$(inst.α).tex", "w") do file
        write(file, str)
    end
end



function rrsp_plot_gF(filename, inst, pars, Fl, Fr)
    """
    - Loads data from file
    - Calls the instance transformation
    - Calls the brute force search algorithms for 3 and 4 hub
    - Creates the master problem.
    """
    println()
    @info "Plotting g(F) ---  $(filename)  ---"

    n = inst.n
    V = inst.V
    V′ = 1:n+1
    tildeV = inst.tildeV
    o = inst.o
    d = inst.d
    d′ = inst.d′
    c = inst.c
    c′ = inst.c′


    exploreplustime = time()

    ncall_bbc = Bool[]

    gurobi_env = Gurobi.Env()
    gurobi_model = Gurobi.Optimizer(gurobi_env)
    m = direct_model(gurobi_model)
    if pars.time_limit > 0
        set_optimizer_attribute(m, "TimeLimit", pars.time_limit)
    end
    set_optimizer_attribute(m, "Threads", pars.nthreads)
    set_optimizer_attribute(m, "OutputFlag", min(pars.log_level, 1))
    set_optimizer_attribute(m, "PreCrush", 1)
    set_optimizer_attribute(m, "MIPFocus", 0)

    # set_optimizer_attribute(m, "MIPGap", 1e-10)
    set_optimizer_attribute(m, "MIPGap", ε)
    # set_optimizer_attribute(m, "MIPGap", 0.985)
    pars.log_level == 0 && set_silent(m)


    @variable(m, x[i=V, j=i+1:n+1], Bin)
    @variable(m, y[i=V′, j=V′], Bin)
    if pars.solve_mod == "g(F)exploreonlyILP"
        @variable(m, x′[i=V, j=i+1:n+1], Bin)
        @variable(m, y′[i=V, j=V; i != j], Bin)
        @variable(m, θ[i=V, j=setdiff(tildeV, i)] >= 0)
    end
    
    if pars.solve_mod == "g(F)"
        time_BSInf = time()
        BSInf, hub1, hub2, hub3 = computeBSInf(inst)
        time_BSInf = round(time() - time_BSInf,digits=5)
        println("ComputeBSInf found BSInf = $BSInf in $(time_BSInf)s")

        @variable(m, B >= BSInf)
    else
        @variable(m, B ≥ 0)
    end


    @constraint(m, s_t_connected, x[1,n+1] == 1)
    @constraint(m, number_hubs_1, sum(y[i, i] for i in V) >= 4)


    @constraint(m, degree_constraint_2[i=setdiff(V′, 1, n + 1)], sum(x[mima(i, j)] for j in V′ if i != j) == 2y[i, i])

    @constraint(m, depot_connected_4, sum(x[1, i] for i in setdiff(V, 1)) == 1)
    @constraint(m, depot_connected_5, sum(x[i, n+1] for i in setdiff(V, 1)) == 1)

    @constraint(m, depotishub_s, y[1, 1] == 1)
    @constraint(m, depotishub_t, y[n+1, n+1] == 1)
    @constraint(m, depot_s_not_aterminal[i = setdiff(V′, 1)], y[1, i] == 0)
    @constraint(m, depot_t_not_aterminal[i = setdiff(V′, n + 1)], y[n+1, i] == 0)


    @constraint(m, hub_or_star_7[i=V], sum(y[i, j] for j in V) == 1)


    function f(x, y)
        sum(sum(c[i,j]*x[i,j] for j in V if i < j; init=0) for i in V) + sum(c[1,i]*x[i,n+1] for i in 2:n) + sum(sum(d[i,j]*y[i,j] for j in V if i != j) for i in V) + sum(o[i]*y[i,i] for i in V)
    end
    if pars.solve_mod == "g(F)exploreonlyILP"
        for i in V
            for k in i+1:n+1
                for j in tildeV
                    if j != i && j != k
                        @constraint(m, x[mima(i, j)] + x[mima(j, k)] <= 1 + x′[mima(i, k)])
                    end
                end
            end
        end
        @constraint(m, recovery_terminal_10[i=V], sum(y′[i, j] for j in V if j != i) == 1 - y[i, i] - sum(y[i, j] for j in setdiff(V, tildeV, i)))

        @constraint(m, one_edge_or_arc_between_i_and_j_11[i=V, j=setdiff(V, i)], x[mima(i, j)] + y[i, j] + x′[mima(i, j)] + y′[i, j] <= y[j, j])
        @constraint(m, reconnecting_star_cost_13[i=V, j=setdiff(tildeV, i)], sum(d′[i, k] * (y′[i, k] + y[i, j] - 1) for k in setdiff(V, i, j)) <= θ[i, j])

        @constraint(m, backup_cost_14[i=V, j=tildeV, k=i+1:n+1; i != j && j != k], c′[mima(i, k)] * (x′[mima(i, k)] + x[mima(i, j)] + x[mima(j, k)] - 2) + sum(θ[t, j] for t in setdiff(V, j)) <= B)
 
    else


        @constraint(m, one_edge_or_arc_between_i_and_j_11[i=V, j=setdiff(V, i)], x[mima(i, j)] + y[i, j] <= y[j, j])
    end

    subtourlazy_cons = Tuple{AffExpr, AffExpr}[]
    nsubtour_cons = Int[0, 0]


    @variable(m, const_term_K)
    @variable(m, const_term_B)

    con_K = @constraint(m, conterm_K, sum(sum(c[i,j]*x[i,j] for j in V if i < j; init=0) for i in V) + sum(c[1,i]*x[i,n+1] for i in 2:n) + sum(sum(d[i,j]*y[i,j] for j in V if i != j) for i in V) + sum(o[i]*y[i,i] for i in V) ≥ const_term_K)
    con_B = @constraint(m, conterm_B, B ≥ const_term_B)


    gurobi_env = Gurobi.Env()








    







    if pars.solve_mod == "g(F)exploreonlyBen"
        Sl, Slobj, x̂, ŷ, B_computed, explore_time = create_S(m, x, y, Fl, B, "l", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    else
        Sl, Slobj, x̂, ŷ, B_computed, explore_time = create_S(m, x, y, Fl, B, "l", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
    end
    list_Fm_Sm = Fm_Sm(Fl, Fl * pars.backup_factor, Sl, explore_time)
    pars.log_level > 0 && println("Storing solution... g(Sl)=$(compute_gS(Sl, Fl)), KSl=$(Sl.K), BSl=$(Sl.B), Fl=$Fl")
    for i in V
        for j in i+1:n+1
            set_start_value(x[i,j], x̂[i,j])
        end
    end
    for i in V′
        for j in V′
           set_start_value(y[i,j], ŷ[i,j]) 
        end
    end
    set_start_value(B, B_computed)
    if pars.solve_mod == "g(F)exploreonlyBen"
        Sr, Srobj, x̂, ŷ, B_computed, explore_time = create_S(m, x, y, Fr, B, "r", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons)
        explore(Fl, Sl, Fr, Sr, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    elseif pars.solve_mod == "g(F)exploreonlyILP"
        Sr, Srobj, x̂, ŷ, B_computed, explore_time = create_S(m, x, y, Fr, B, "r", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
        explore(Fl, Sl, Fr, Sr, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
    else
        time_KSInf = time()

    
        KSInf, x̂, ŷ = rrsp_create_ilp_lazyexplore(filename, inst, pars, nsubtour_cons, subtourlazy_cons, BSInf, Sl.K, hub1, hub2, hub3)
        time_KSInf = round(time() - time_KSInf,digits=1)
        B_computed = compute_B_critical_tripletexplore(inst, x̂, ŷ)[1]
    
        @info B_computed
        println("ComputeKSInf found KSInf = $KSInf in $(time_KSInf)s")
        push!(ncall_bbc, true)

        SInf = SKB(KSInf, BSInf)
        explore_plus(Fl, Sl, SInf, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    end





    list_Fm_Sm = sort_filter(list_Fm_Sm)
    @show list_Fm_Sm
    for i in 1:length(list_Fm_Sm.F)
        @show list_Fm_Sm.sKB[i]
    end

    write_tikz_list_Fm_Sm(list_Fm_Sm, filename, exploreplustime, ncall_bbc, inst, pars)

end



function create_S(m, x, y, Fm, B, str_lmr, f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′=nothing, y′=nothing)
    println("\nLauching create_S (B&BC) $(str_lmr == Inf ? "ComputeKSInf" : "with F=$Fm")")
    n = inst.n
    V = inst.V
    o = inst.o
    d = inst.d
    c = inst.c


    if pars.solve_mod == "g(F)exploreonlyBen"
        m, explore_time, m_time, s_time, blossom_time, t_two_opexplore_time, TL_reached, gap, UB, LB, x̂, ŷ, nopt_cons, nsubtour_cons, nconnectivity_cuts, ntwo_opt, nblossom, explored_nodes = benders_st_optimize_explore!(m, x, y, f, Fm, B, str_lmr, inst, pars, time(), gurobi_env, subtourlazy_cons, nsubtour_cons, ncall_bbc)
    else

        m, explore_time, blossom_time, TL_reached, gap, UB, LB, x̂, ŷ, nsubtour_cons, nconnectivity_cuts, nblossom, explored_nodes = ilp_st_optimize_explore!(m, x, y, x′, y′, f, Fm, B, inst, pars, time(), gurobi_env, subtourlazy_cons, nsubtour_cons, ncall_bbc; log_level=3)
    end



    push!(ncall_bbc, true)

    B_computed, i★, j★, k★, = -1, -1, -1, -1
    if has_values(m)

        x̂_bool = Dict{Tuple{Int,Int},Bool}()
        x̂′_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ′_bool = Dict{Tuple{Int,Int},Bool}()


        for i in 1:n
            for j in 1:n+1
                if j > i
                    x̂_bool[i, j] = x̂[i, j] > 0.5
                end
                if j < n + 1
                    ŷ_bool[i, j] = ŷ[i, j] > 0.5
                end
            end
        end

        ŷ′_bool = sp_optimize_ilp_primal(x̂_bool, ŷ_bool, inst, pars.log_level, gurobi_env)[3]

        ring = create_ring_edges_lazy(x̂_bool, n)
        ŷ′_postopt = ŷ′_bool
        if pars.post_procedure
            ŷ_postopt, ŷ′_postopt = post_optimization_procedure(inst, ŷ_bool, ŷ′_bool)[1:2]
        end

        print_ring_nodes(ŷ, n, false)
        print_ring_edges(x̂′_bool, inst.c, n)
        print_star_edges(ŷ_postopt, inst.d, n)
        print_star_edges(ŷ′_postopt, inst.d′, n, true)

    end

    @assert !TL_reached && gap < ε


    B_computed = compute_B_critical_tripletexplore(inst, x̂_bool, ŷ_bool)[1]

    Sm = SKB(f(x̂_bool, ŷ_bool), B_computed)


    pars.log_level > 0 && println("B&BC solution, g(S$str_lmr)=$(compute_gS(Sm, Fm)), KS$str_lmr=$(Sm.K), BS$str_lmr=$(Sm.B), F$str_lmr=$Fm")
    return Sm, objective_value(m), x̂, ŷ, B_computed, explore_time, ncall_bbc
end




function explore(Fl, Sl, Fr, Sr, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′=nothing, y′=nothing)

    n = inst.n
    V = inst.V
    V′ = 1:n+1
    o = inst.o
    d = inst.d
    c = inst.c

    KSl = Sl.K
    BSl = Sl.B
    KSr = Sr.K
    BSr = Sr.B

    pars.log_level > 0 && println("\nExplore F_left=$Fl, Explore F_right=$Fr")

    if abs(BSl - BSr) < ε
        return
    end

    Fm = (KSr - KSl) / (BSl - BSr)
    pars.log_level > 0 && println("Computed Fm=$Fm\n")
    if abs(Fm - Fl) < ε
        pars.log_level > 0 && println("Storing solution... g(Sr)=$(BSr*Fr+KSr), KSr=$KSr, BSr=$BSr, Fl=$Fl")
        push!(list_Fm_Sm, (Fl, Sr, explore_time), pars.backup_factor)
        return
    end
    if abs(Fm - Fr) < ε
        pars.log_level > 0 && println("Storing solution... g(Sl)=$(BSl*Fl+KSl), KSl=$KSl, BSl=$BSl, Fl=$Fl")
        push!(list_Fm_Sm, (Fl, Sl, explore_time), pars.backup_factor)
        return
    end
    for i in V
        for j in i+1:n+1
            set_start_value(x[i,j], x̂[i,j])
        end
    end
    for i in V′
        for j in V′
           set_start_value(y[i,j], ŷ[i,j]) 
        end
    end
    set_start_value(B, B_computed)

    fix(const_term_K, KSl)
    fix(const_term_B, BSr)
    if pars.solve_mod == "g(F)exploreonlyBen"
        Sm, Smobj, x̂, ŷ, B_computed, bc_time = create_S(m, x, y, Fm, B, "m", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    else
        Sm, Smobj, x̂, ŷ, B_computed, bc_time = create_S(m, x, y, Fm, B, "m", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
    end



    if abs(KSl + Fm * BSl - Sm.K - Fm * Sm.B) < ε
        pars.log_level > 0 && println("Storing solution... g(Sr)=$(BSr*Fr+KSr), KSr=$KSr, BSr=$BSr, Fm=$Fm")
        push!(list_Fm_Sm, (Fm, Sr, explore_time), pars.backup_factor)
        return
    end
    if pars.solve_mod == "g(F)exploreonlyBen"
        explore(Fl, Sl, Fm, Sm, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
        explore(Fm, Sm, Fr, Sr, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    else
        explore(Fl, Sl, Fm, Sm, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
        explore(Fm, Sm, Fr, Sr, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons, x′, y′)
    end
end


function explore_plus(Fl, Sl, SInf, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)

    n = inst.n
    V = inst.V
    V′ = 1:n+1
    o = inst.o
    d = inst.d
    c = inst.c

    KSl = Sl.K
    KSInf = SInf.K
    BSl = Sl.B
    BSInf = SInf.B
    pars.log_level > 0 && println("\nLauching Explore Plus KSl=$KSl, BSl=$BSl, Fl=$Fl, KSInf=$KSInf, BSInf=$BSInf")

    if abs(BSl - BSInf) < ε
        return
    end
    Fm = (KSInf - KSl)/(BSl - BSInf)
    if abs(Fl - Fm) < ε
        pars.log_level > 0 && println("Storing solution... g(SInf)=$(BSl*Fl+KSl), KSl=$KSl, BSl=$BSl, Fl=$Fl")
        push!(list_Fm_Sm, (Fl, SInf, explore_time), pars.backup_factor)
        return
    end
    for i in V
        for j in i+1:n+1
            set_start_value(x[i,j], x̂[i,j])
        end
    end
    for i in V′
        for j in V′
           set_start_value(y[i,j], ŷ[i,j]) 
        end
    end
    set_start_value(B, B_computed)
    fix(const_term_K, KSl)
    fix(const_term_B, BSInf)
    # @constraint(m, sum(sum(c[i,j]*x[i,j] for j in V if i < j; init=0) for i in V) + sum(c[1,i]*x[i,n+1] for i in 2:n) + sum(sum(d[i,j]*y[i,j] for j in V if i != j) for i in V) + sum(o[i]*y[i,i] for i in V) ≥ KSl)
    Sm, Smobj, x̂, ŷ, B_computed, explore_time = create_S(m, x, y, Fm, B, "m", f, inst, pars, gurobi_env, ε, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    KSm = Sm.K
    BSm = Sm.B
    if abs(KSl + Fm*BSl - KSm - Fm*BSm) < ε
        pars.log_level > 0 && println("Storing solution... g(SInf)=$(BSm*Fm+KSm), KSm=$KSm, BSm=$BSm, Fm=$Fm")
        push!(list_Fm_Sm, (Fm, SInf, explore_time), pars.backup_factor)
        return
    end

    explore(   Fl, Sl, Fm, Sm, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
    explore_plus(Fm, Sm, SInf, list_Fm_Sm, m, f, const_term_K, const_term_B, inst, gurobi_env, x̂, ŷ, B_computed, x, y, B, ε, explore_time, ncall_bbc, subtourlazy_cons, nsubtour_cons)
end


function computeBSInf(inst)
    
    V = inst.V
    c′ = inst.c′
    n = inst.n

    hub1, hub2, hub3 = -1, -1, -1
    tildeV = inst.tildeV
    @show tildeV
    BSInf = Inf
    if length(tildeV) + 3 ≤ n
        BSInf = 0
    else
        AE = Tuple{Int,Int}[]
        for i in tildeV
            for j in i+1:n
                if j in tildeV
                    push!(AE, (i,j))
                end
            end
        end
        sort!(AE, by=x->c′[mima(x[1],x[2])])

        AV = Int[]
        for i in tildeV
            push!(AV, i)
        end
        sort!(AV, by=x->c′[1, x])
        
        if length(tildeV) + 2 == n
            w = setdiff(V, tildeV)[1]
            if w == 1
                w = setdiff(V, tildeV)[2]
            end
            BSInf = c′[1, w]
        else    
            BSInf = Inf
        end
        v = 1
        found = false
        while v ≤ length(AV) && !found
            i = AV[v]
            if c′[1,i] >= BSInf
                found = true
            else
                e = 1
                pruned = false
                while e ≤ length(AE) && !pruned
                    mimae = mima(AE[e][1], AE[e][2])
                    if c′[mimae] > c′[1,i] # line 18
                        pruned = true
                    elseif AE[e][1] ≠ i && AE[e][2] ≠ i
                        BSInf = c′[1,i] # line 21
                        hub1 = i
                        hub2 = mimae[1]
                        hub3 = mimae[2]
                    end
                    e += 1
                end
            end
            v += 1
        end
        e = 1   
        found = false   

        while e ≤ length(AE) && !found
            mimae = mima(AE[e][1], AE[e][2])
            if c′[mimae] >= BSInf
                found = true
            else
                v = 1
                i = AV[v]
                pruned = false
                while v ≤ length(AV) && !pruned
                    if c′[1,i] > c′[mimae] # line 33
                        pruned = true
                    elseif AE[e][1] ≠ i && AE[e][2] ≠ i
                        BSInf = c′[mimae]
                        hub1 = i
                        hub2 = mimae[1]
                        hub3 = mimae[2]
                    end
                    v += 1
                end
                e += 1
            end
        end
    end
    @show BSInf, hub1, hub2, hub3
    return BSInf, hub1, hub2, hub3
end

