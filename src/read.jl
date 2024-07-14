function read_ilp_table(filepath, id_sol)
    data_str = split(chop(read(filepath, String), head = 40))

    n = parse(Int, data_str[6])
    i = 0
    idx_start = 9
    while i < id_sol
        if data_str[idx_start] == "———————" # We currently are in a new solution
            i += 1
        end
        idx_start += 1
    end
    idx_start -= 10
    nhubs = parse(Int, data_str[idx_start+23])
    hubs = parse.(Int, split(data_str[idx_start+26], '—'))
    idx_shift_ilp = 0
    t_time = parse(Float64, data_str[idx_start+29])
    TL_reached = false
    if data_str[idx_start+30] == "(TL"
        idx_shift_ilp += 2
        TL_reached = true
    end
    idx_start += idx_shift_ilp
    ilp_gap = parse(Float64, data_str[31+idx_start])
    LB_ilp, UB_ilp = parse.(Float64, split(data_str[35+idx_start], "<="))
    n_subtour_ILP = parse(Float64, data_str[37+idx_start])
    nconnectivity_cuts = parse(Float64, data_str[40+idx_start])
    two_opt_time = parse(Float64, data_str[54+idx_start])
    ntwo_opt = parse(Float64, data_str[57+idx_start])
    nedges_cuts = parse(Float64, data_str[61+idx_start])


    x_opt = Dict{Tuple{Int,Int},Bool}()
    x′_opt = Dict{Tuple{Int,Int},Bool}()
    y_opt = Dict{Tuple{Int,Int},Bool}()
    y′_opt = Dict{Tuple{Int,Int},Bool}()
    idx_opt = 73 + idx_start

    function affect_dict!(opt, data_str, str, idx)
        while data_str[idx] != str
            opt[parse(Int, data_str[idx]), parse(Int, data_str[idx+2])] = true
            idx += 6
        end
        idx += 1
        return idx
    end

    idx_opt = affect_dict!(x_opt, data_str, "STAR", idx_opt)

    idx_opt = affect_dict!(y_opt, data_str, "BACKUP", idx_opt)
    idx_opt += 1
    idx_opt = affect_dict!(x′_opt, data_str, "BACKUP", idx_opt)
    idx_opt += 1
    idx_opt = affect_dict!(y′_opt, data_str, "B", idx_opt)

    B = parse(Float64, data_str[idx_opt+1])
    i★ = parse(Int, data_str[idx_opt+4])
    j★ = parse(Int, data_str[idx_opt+7])
    k★ = parse(Int, data_str[idx_opt+10])

    sol = Solution(n, hubs, x_opt, x′_opt, y_opt, y′_opt, B, i★, j★, k★)

    return ILPtable(
        t_time,
        two_opt_time,
        TL_reached,
        ilp_gap,
        UB_ilp,
        LB_ilp,
        n_subtour_ILP,
        nconnectivity_cuts,
        nedges_cuts,
        ntwo_opt,
        nhubs,
        sol,
    )
end
