function log_assert(filename, left_hs, operator, right_hs, error_str = "")
    if !operator(left_hs, right_hs)
        open(
            eval(@__DIR__) *
            "/debug/$(filename)_$(Dates.format(now(), "yyyy-mm-dd__HHhMM")).txt",
            "w",
        ) do file
            write(file, "left hand side: $left_hs !$operator right hand side: $right_hs\n")
            write(file, error_str)
            @test false
        end
        @test true
        # @assert operator(left_hs, right_hs)
    end
end


function resilient_checker(filename, inst, x, x′, y, y′, gap, B, obj; log_level = 1)
    V = inst.V
    tildeV = inst.tildeV
    o = inst.o
    c = inst.c
    c′ = inst.c′
    d = inst.d
    d′ = inst.d′
    F = inst.F



    E = [(i, j) for i in V, j in V if i < j]
    A = [(i, j) for i in V, j in V]
    n = length(V)
    V′ = union(V, n + 1)

    error = 0.1

    checked_obj = 0

    n_hubs = 0
    for i in V
        if y[i, i] > 0.5
            n_hubs += 1
            checked_obj += o[i]
        end
    end

    log_assert(filename, n_hubs, >=, 4, "Number of hubs is not greater than 4")
    log_level > 0 && @show n_hubs

    for i in V
        for j in V
            if i != j
                if y[i, j] > 0.5
                    checked_obj += d[i, j]
                    log_assert(
                        filename,
                        y[i, i],
                        <,
                        0.5,
                        "$i is not a terminal while y[$i,$j] is true",
                    )
                    log_assert(
                        filename,
                        y[j, j],
                        >,
                        0.5,
                        "$j is not a hub while y[$i,$j] is true",
                    )

                    !haskey(y′, (i, j)) || log_assert(
                        filename,
                        y′[i, j],
                        <,
                        0.5,
                        "y′[$i, $j] is true while y[$i, $j] is also true",
                    )
                    log_assert(
                        filename,
                        x[mima(i, j)],
                        <,
                        0.5,
                        "x[$(mima(i,j)[1]), $(mima(i,j)[2])] is true while y[$i, $j] is also true",
                    )
                    !haskey(x′, (i, j)) || log_assert(
                        filename,
                        x′[mima(i, j)...],
                        <,
                        0.5,
                        "x'[$(mima(i,j)[1]), $(mima(i,j)[2])] is true while y[$i, $j] is also true",
                    )
                end
                if i < j && x[i, j] > 0.5
                    checked_obj += c[i, j]
                    log_assert(
                        filename,
                        y[i, i],
                        >,
                        0.5,
                        "y[$i, $i] must be true because x[$i,$j] is true",
                    )
                    log_assert(
                        filename,
                        y[j, j],
                        >,
                        0.5,
                        "y[$j, $j] must be true because x[$i,$j] is true",
                    )

                    !haskey(x′, (i, j)) || log_assert(
                        filename,
                        x′[i, j],
                        <,
                        0.5,
                        "x'[$i, $j] is true while x[$i, $j] is also true",
                    )
                    log_assert(
                        filename,
                        y[i, j],
                        <,
                        0.5,
                        "y[$i, $j] is true while x[$i, $j] is also true",
                    )
                    !haskey(y′, (i, j)) || log_assert(
                        filename,
                        y′[i, j],
                        <,
                        0.5,
                        "y′[$i, $j] is true while x[$i, $j] is also true",
                    )

                end
            end
        end
        if i != 1 && x[i, n+1] > 0.5
            checked_obj += c[1, i]
            log_assert(
                filename,
                y[i, i],
                >,
                0.5,
                "$i must be a hub because x[$i, n+1] is selected",
            )
            log_assert(
                filename,
                y[n+1, n+1],
                >,
                0.5,
                "n+1 must be a hub because x[$i, n+1] is selected",
            )
            !haskey(x′, (i, n + 1)) || log_assert(
                filename,
                x′[i, n+1],
                <,
                0.5,
                "x'[$i,n+1] must be false because x[$i, n+1] is selected",
            )
        end
    end

    max_backup_cost_star = 0
    max_backup_cost = 0
    max_j = -1
    for j in V
        backup_cost_j = 0.0
        backup_cost_star_j = 0.0
        if j in tildeV && y[j, j] > 0.5 # j is an uncertain hub
            for i in setdiff(V, j)
                if y[i, j] > 0.5 # j is a hub for terminal i
                    log_assert(
                        filename,
                        y[i, i],
                        <,
                        0.5,
                        "$i must be a terminal because y[$i,$j] is selected",
                    )
                    for k in setdiff(V, i, j)
                        if haskey(y′, (i, k)) && y′[i, k] > 0.5
                            backup_cost_j += d′[i, k]
                            backup_cost_star_j += d′[i, k]
                            log_level > 1 && @show i, j, d′[i, k]
                        end
                    end
                end
            end
            for i in setdiff(V, j)
                for k in setdiff(i+1:n, j)
                    if x[mima(i, j)] > 0.5 && x[mima(k, j)] > 0.5
                        backup_cost_j += c′[mima(i, k)]
                        log_level > 1 && @show i, j, k, c′[mima(i, k)]
                    end
                end
                if x[mima(i, j)] > 0.5 && x[j, n+1] > 0.5
                    backup_cost_j += c′[i, n+1]
                    log_level > 1 && @show i, j, n + 1, c′[i, n+1]
                end
            end
            if log_level >= 1
                log_level > 0 && println(j, " backup cost: ", backup_cost_j)
            end
            if max_backup_cost < backup_cost_j
                max_backup_cost = backup_cost_j

                max_backup_cost_star = backup_cost_star_j
                max_j = j
            end
        end
    end
    if log_level > 1
        println("Worst backup cost, node $max_j: ", max_backup_cost)
    end


    log_level > 0 && @show checked_obj
    log_level > 0 && @show B
    log_level > 0 && @show max_backup_cost
    if B > 0 && F > 0 && !isempty(tildeV) && gap < 10e-5
        log_assert(
            filename,
            abs(B - max_backup_cost),
            <,
            error,
            "checked backup cost $B must be equal to $max_backup_cost. tolerance error=$error",
        )
    end

    checked_obj += F * max_backup_cost

    if obj > 0 && gap < 10e-5
        log_level > 0 && @show obj, checked_obj
        @show obj, checked_obj
        log_assert(
            filename,
            abs(obj - checked_obj),
            <,
            error,
            "checked objective $obj must be equal to $checked_obj. tolerance error=$error",
        )
    end

    return true
end
