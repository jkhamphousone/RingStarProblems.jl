function get_input_filepath(
    output_folder,
    filename,
    extension,
    inst,
    pars,
    nstr_random,
    rand_inst_id,
)
    α_str = pars.nrand == 0 ? "_α=$(inst.α)" : ""
    main_folder_path = "$(output_folder)$(filename[1])$α_str/"
    mkpath(main_folder_path)
    return "$main_folder_path$(filename[1])$(nstr_random)$(α_str)_TL=$(pars.timelimit)$(pars.o_i == "" ? "" : "_oi=$(pars.o_i)_nrand-$(rand_inst_id)")$(pars.two_opt >= 1 ? "_2-opt" : "")_tildeV=$(pars.tildeV)_F=$(inst.F)$extension"
end

function write_solution_to_file(
    output_filepath,
    filename,
    inst,
    pars,
    nstr_random,
    rand_inst_id,
    n,
    benders_table,
    ilp_table,
)

    if pars.writeresults == WHTML() || pars.writeresults == WLocal()
        output_file = write_header(output_filepath, filename, inst, pars)
        writeresultsults(output_file, n, inst, benders_table, ilp_table, pars)

        println(output_file, "$(pars.writeresults == WHTML() ? "</details>" : "")")
        print(output_file, "$(pars.writeresults == WHTML() ? "</pre>" : "")")
        @show output_file
        close(output_file)
    end
end


function write_header(output_filename, filename, inst, pars)
    α_str = pars.nrand == 0 ? "_α-$(inst.α)" : ""
    output_file = open(output_filename, "a")
    is_file_empty = filesize(output_filename)

    if is_file_empty == 0
        println(
            output_file,
            "$(pars.writeresults == WHTML() ? "<body><meta charset=\"utf-8\"></body><pre>" : "")------------------------------------------------------------\n",
            lpad(
                "       $(length(α_str)==0 ? "" : "α=$(inst.α)") —— $(filename[1]) —— $(inst.n) nodes       \n",
                60,
            ),
            "------------------------------------------------------------",
        )
    else
        choppre(output_filename)
    end

    pars.writeresults == WHTML() ||
        pars.writeresults == WLocal() && println(
            output_file,
            "\n——————— $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) ————————— $(pars.ilpseparatingcons_method[1]) ————————— use blossom = $(pars.use_blossom)",
        )
    return output_file
end




function writeresultsults(output_file, n, inst, benders_table, ilp_table, pars)
    rpad_col = 21
    tildeV_string = "empty"
    if length(inst.tildeV) > 0
        tildeV_string = "$(inst.tildeV[1]):$(inst.tildeV[end])"
    end
    if pars.solve_mod in [ILP(), Both()]
        ########### ILP
        print(output_file, "ILP ——— $(length(ilp_table.sol.hubs)) hubs —— ")
        for hub in ilp_table.sol.hubs
            print(output_file, "$hub")
            if hub != ilp_table.sol.hubs[end]
                print(output_file, "—")
            end
        end
        println(output_file)
        TL_ilp = ""
        if ilp_table.TL_reached > 0
            TL_ilp = " (TL $(pars.timelimit))"
        end
        println(
            output_file,
            rpad("total time", rpad_col),
            rpadstrip("$(ilp_table.t_time)$TL_ilp", rpad_col),
            rpad("gap", rpad_col),
            rpadstrip(ilp_table.gap, rpad_col),
        )

        println(
            output_file,
            rpad("blossom time", rpad_col),
            rpadstrip("$(ilp_table.blossom_time)", rpad_col),
            rpad("nb blossom", rpad_col),
            rpad(ilp_table.nblossom, rpad_col),
        )

        println(
            output_file,
            rpad("LB <= UB", rpad_col),
            rpadstrip("$(ilp_table.LB)<=$(ilp_table.UB)", rpad_col),
            rpad("subtour", rpad_col),
            rpadstrip(ilp_table.nsubtour_cons, rpad_col),
        )

        println(
            output_file,
            rpad("connectivity cuts", rpad_col),
            rpadstrip(ilp_table.nconnectivity_cuts, rpad_col),
            rpad("uc strategy", rpad_col),
            rpadstrip(pars.ucstrat, rpad_col),
        )



        println(
            output_file,
            rpad("uc tolerance", rpad_col),
            rpadstrip(pars.uctolerance, rpad_col),
            rpad("tildeV", rpad_col),
            rpad(tildeV_string, rpad_col),
        )

        println(
            output_file,
            rpad("2-opt strategy", rpad_col),
            rpad(pars.two_opt, rpad_col),
            rpad(pars.two_opt >= 1 ? "2-opt time" : "", rpad_col),
            rpadstrip(pars.two_opt >= 1 ? ilp_table.two_opt_time : "", rpad_col),
        )

        println(
            output_file,
            rpad("explored_nodes", rpad_col),
            rpad(ilp_table.nodes_explored, rpad_col),
            rpad("n lazycuts edges", rpad_col),
            rpadstrip(ilp_table.nedges_cuts, rpad_col),
        )


        println(
            output_file,
            rpad("F", rpad_col),
            rpad(inst.F, rpad_col),
            rpad("post procedure", rpad_col),
            rpadstrip(pars.post_procedure, rpad_col),
        )


        print(
            output_file,
            rpad(pars.o_i == "" ? "" : "o_i", rpad_col),
            rpad(pars.o_i == "" ? "" : pars.o_i, rpad_col),
            rpad("r_ij", rpad_col),
            rpad("$(pars.r_ij)\n", rpad_col),
        )

        print(output_file, rpad("s_ij", rpad_col), rpad("$(pars.s_ij)\n", rpad_col))

        print(
            output_file,
            rpad(length(pars.warm_start) == 0 ? "" : "warm_start", rpad_col),
            rpad(length(pars.warm_start) == 0 ? "" : pars.warm_start * '\n', rpad_col),
        )


        println(
            output_file,
            "$(pars.writeresults == WHTML() ? "<details><summary>Found solution</summary>" : "")",
        )
        print_solution(output_file, ilp_table.sol, inst)
        println(output_file, "$(pars.writeresults == WHTML() ? "</details>" : "")")

    end
    ########### Benders
    if pars.solve_mod in [BranchBendersCut(), Both]
        print(output_file, "BD  —— $(length(benders_table.sol.hubs)) hubs —— ")
        for hub in benders_table.sol.hubs
            print(output_file, "$hub")
            print(output_file, "-")
            if hub == benders_table.sol.hubs[end]
                print(output_file, "1")
            end
        end
        println(output_file)

        TL_benders = ""
        if benders_table.TL_reached > 0
            TL_benders = " (TL $(pars.timelimit))"
        end
        println(
            output_file,
            rpad("total time", rpad_col),
            rpadstrip("$(benders_table.t_time)$TL_benders", rpad_col),
            rpad("gap", rpad_col),
            rpadstrip(benders_table.gap, rpad_col),
        )

        println(
            output_file,
            rpad("blossom time", rpad_col),
            rpadstrip("$(benders_table.blossom_time)", rpad_col),
            rpad("nb blossom", rpad_col),
            rpad(benders_table.nblossom, rpad_col),
        )

        println(
            output_file,
            rpad("LB <= UB", rpad_col),
            rpadstrip("$(benders_table.LB)<=$(benders_table.UB)", rpad_col),
            rpad("Master/SP costs", rpad_col),
            rpadstrip("$(benders_table.m_cost)/$(benders_table.sp_cost)", rpad_col),
        )
        println(
            output_file,
            rpad("Master time", rpad_col),
            rpadstrip(benders_table.m_time, rpad_col),
            rpad("SP time", rpad_col),
            rpadstrip(benders_table.s_time, rpad_col),
        )

        println(
            output_file,
            rpad("subtour", rpad_col),
            rpadstrip(benders_table.nsubtour_cons, rpad_col),
            rpad("connectivity cuts", rpad_col),
            rpadstrip(benders_table.nconnectivity_cuts, rpad_col),
        )

        println(
            output_file,
            rpad("uc strategy", rpad_col),
            rpadstrip(pars.ucstrat, rpad_col),
            rpad("uc tolerance", rpad_col),
            rpadstrip(pars.uctolerance, rpad_col),
        )


        println(
            output_file,
            rpad("opt. cuts", rpad_col),
            rpadstrip(benders_table.nopt_cons, rpad_col),
            rpad("SP method", rpad_col),
            rpad(pars.sp_solve, rpad_col),
        )

        println(
            output_file,
            rpad("tildeV", rpad_col),
            rpad("$(tildeV_string)", rpad_col),
            rpad("inst transformation", rpad_col),
            rpad(pars.inst_trans, rpad_col),
        )


        println(
            output_file,
            rpad("2-opt strategy", rpad_col),
            rpad(pars.two_opt, rpad_col),
            rpad(pars.two_opt >= 1 ? "2-opt time" : "", rpad_col),
            rpad(pars.two_opt >= 1 ? benders_table.two_opt_time : "", rpad_col),
        )

        println(
            output_file,
            rpad("explored nodes", rpad_col),
            rpad(benders_table.nodes_explored, rpad_col),
        )

        println(output_file, rpad("F", rpad_col), rpad(inst.F, rpad_col))
        print(
            output_file,
            rpad(length(pars.warm_start) == 0 ? "" : "warm_start", rpad_col),
            rpad(length(pars.warm_start) == 0 ? "" : pars.warm_start * '\n', rpad_col),
        )

        println(
            output_file,
            rpad(pars.o_i == "" ? "" : "o_i", rpad_col),
            rpad(pars.o_i == "" ? "" : pars.o_i, rpad_col),
            rpad(pars.r_ij == "" ? "" : "r_ij", rpad_col),
            rpad(pars.r_ij == "" ? "" : pars.r_ij, rpad_col),
        )

        println(output_file, rpad("s_ij", rpad_col), rpad("$(pars.s_ij)", rpad_col))

        println(
            output_file,
            "$(pars.writeresults == WHTML() ? "<details><summary>Found solution</summary>" : "")",
        )
        print_solution(output_file, benders_table.sol, inst)
        println(output_file, "$(pars.writeresults == WHTML() ? "</details>" : "")")

    end

end

rpadstrip(str, i) =
    rpad(length(str) > 2 ? str[1:end-2] * replace(str[end-1:end], ".0" => "") : str, i)


function print_ring_nodes(y, n, print_term = true)
    str = "RING NODES\n"
    opened = Int[]
    for i = 1:n
        if y[i, i] > 0.5
            push!(opened, i)
        end
    end
    for nodes in opened
        str *= "$nodes "
    end
    str *= "\n\n"
    print_term && print(str)
    return str
end

function print_hubs(x::Vector{Int}, print_term = true)
    # x is a vector of hubs
    str = "RING NODES\n"
    for nodes in x
        str *= "$(nodes)—"
    end
    str = chop(str)
    str *= "\n\n"
    print_term && print(str)
    return str
end

function print_ring_nodes(x, node, current_node, visited, n)
    # TODO recode this function
    ring = Dict{Int,Vector{Int}}()
    for i = 1:n
        ring[i] = Int[]
    end
    for i = 1:n
        for j = i+1:n
            # @show callback_value(cb_data, x[i,j+i])
            if x[i, j] > 0.5
                push!(ring[i], j)
                push!(ring[j], i)
            end
        end
    end

    print(current_node, " ")
    if (node == current_node) && !visited[current_node]
        visited[current_node] = true
        if length(ring[current_node]) == 0
            return
        end
        child = ring[current_node][1]

        return print_ring_nodes(x, node, child, deepcopy(visited), n)
    end
    visited[current_node] = true
    if !visited[ring[current_node][1]]
        return print_ring_nodes(x, node, ring[current_node][1], deepcopy(visited), n)
    end
    if !visited[ring[current_node][2]]
        return print_ring_nodes(x, node, ring[current_node][2], deepcopy(visited), n)
    end
    return
end


function print_ring_edges(x, ring_costs, n, backup = false, print_term = true)
    str = "$(backup ? "BACKUP " : "")RING\n"
    for i = 1:n
        for j = i+1:n+1
            if haskey(x, (i, j)) && x[i, j] > 0.5
                str *= "$(rpad("$i ", 3))---$(lpad(" $j", 3)) | cost [$(ring_costs[i,j])]\n"
            end
        end
    end
    str *= "\n"
    print_term && print(str)
    return str
end




function print_star_edges(x, star_costs, n, backup = false, print_term = true)
    str = "$(backup ? "BACKUP " : "")STAR\n"
    for i = 1:n
        for j = 1:n
            if i != j && haskey(x, (i, j)) && x[i, j] > 0.5
                str *= "$(rpad("$i ", 3))-->$(lpad(" $j", 3)) | cost [$(star_costs[mima(i, j)])]\n"
            end
        end
    end
    str *= "\n"
    print_term && print(str)
    return str
end

print_star_edges(x, n) = print_star_edges(x, zeros(Int64, n, n), n)
