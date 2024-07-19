function sp_optimize_ilp_dual(x̂, ŷ, inst, log_level, first_sp_m, optimizer)
    n = length(inst.V)
    tildeV = inst.tildeV
    V = inst.V
    V′ = 1:n+1
    tildeJ = Set([(i, j, k) for i in V, j in tildeV, k in V′ if i != j && j != k && i < k])
    d′ = inst.d′
    c′ = inst.c′

	sp_m = Model(optimizer)
    set_silent(sp_m)

    if first_sp_m

        log_level <= 1 && set_silent(sp_m)

        @variable(sp_m, α[V])
        @variable(sp_m, β[i = V, j = tildeV, k = V′; (i, j, k) in tildeJ] >= 0)
        @variable(sp_m, γ[i = V, j = setdiff(tildeV, i)] >= 0)
        @variable(sp_m, δ[i = V, j = tildeV, k = V′; (i, j, k) in tildeJ] >= 0)
        @variable(sp_m, ζ[i = V, j = V; i != j] >= 0)

        λα = @expression(
            sp_m,
            sum(
                (1 - ŷ[i, i] - sum(ŷ[i, j] for j in setdiff(V, tildeV, i)))α[i] for i in V
            )
        )
        λβ = @expression(
            sp_m,
            sum((x̂[mima(i, j)] + x̂[mima(j, k)] - 1)β[i, j, k] for (i, j, k) in tildeJ)
        )
        λγ = @expression(
            sp_m,
            sum(
                (sum(d′[i, k] * (ŷ[i, j] - 1) for k in setdiff(V, i, j)))γ[i, j] for
                i in V, j in setdiff(tildeV, i)
            )
        )
        λδ = @expression(
            sp_m,
            sum(
                c′[i, k] * (x̂[mima(i, j)] + x̂[mima(j, k)] - 2)δ[i, j, k] for
                (i, j, k) in tildeJ
            )
        )
        λζ = @expression(
            sp_m,
            sum(
                (x̂[mima(i, j)] + ŷ[i, j] - ŷ[j, j])ζ[i, j] for i in V,
                j in setdiff(V, i)
            )
        )


        @objective(sp_m, Max, λα + λβ + λγ + λδ + λζ)


        @constraint(
            sp_m,
            x′ik[i = V, k = V; i < k],
            sum(β[i, j, k] - c′[i, k]δ[i, j, k] for j in tildeV if i != j && j != k) -
            ζ[i, k] - ζ[k, i] <= 0
        )

        @constraint(
            sp_m,
            x′it[i = setdiff(V, 1)],
            sum(
                β[(i, j, n + 1)] - c′[i, n+1]δ[(i, j, n + 1)] for
                j in tildeV if i != j && j != n + 1
            ) <= 0
        )


        @constraint(sp_m, B, sum(δ[i, j, k] for (i, j, k) in tildeJ) <= inst.F)


        @constraint(
            sp_m,
            y′ij[i = V, j = V; i != j],
            α[i] - d′[i, j]sum(γ[i, k] for k in setdiff(tildeV, i, j)) - ζ[i, j] <= 0
        )

        @constraint(
            sp_m,
            θ_ij[i = V, j = setdiff(tildeV, i)],
            γ[i, j] - sum(
                δ[(q, j, k)] for
                q in V, k in V′ if q != j && k != j && q < k && !(q == 1 && k == n + 1)
            ) <= 0
        )
    else

        @objective(
            sp_m,
            Max,
            sum(
                (1 - ŷ[i, i] - sum(ŷ[i, j] for j in setdiff(V, tildeV, i)))sp_m[:α][i] for
                i in V
            ) +
            sum(
                (x̂[mima(i, j)] + x̂[mima(j, k)] - 1)sp_m[:β][i, j, k] for
                (i, j, k) in tildeJ
            ) +
            sum(
                (sum(d′[i, k] * (ŷ[i, j] - 1) for k in setdiff(V, i, j)))sp_m[:γ][i, j] for
                i in V, j in setdiff(tildeV, i)
            ) +
            sum(
                c′[i, k] * (x̂[mima(i, j)] + x̂[mima(j, k)] - 2)sp_m[:δ][i, j, k] for
                (i, j, k) in tildeJ
            ) +
            sum(
                (x̂[mima(i, j)] + ŷ[i, j] - ŷ[j, j])sp_m[:ζ][i, j] for i in V,
                j in setdiff(V, i)
            )
        )
    end


    optimize!(sp_m)

    first_sp_m = false



    return objective_value(sp_m),
    value.(sp_m[:α]),
    value.(sp_m[:β]),
    value.(sp_m[:γ]),
    value.(sp_m[:δ]),
    value.(sp_m[:ζ])
end
