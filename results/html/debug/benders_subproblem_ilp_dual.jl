function sp_optimize_ilp_dual(x̂, ŷ, inst, log_level, gurobi_env)
    n = length(inst.V)

    ifelse(pars.F == 0, 1:1, inst.tildeV)
    V = inst.V
    V′ = 1:n+1
    d′ = inst.d′
    c′ = inst.c′
    tildeJ = Set([(i, j, k) for i in V, j in tildeV, k in V′ if i != j && j != k && i < k])

    gurobi_model = Gurobi.Optimizer(gurobi_env)
    sp_m = direct_model(gurobi_model)
    set_optimizer_attribute(sp_m, "OutputFlag", 0)

    log_level <= 1 && set_silent(sp_m)

    @variable(sp_m, α[V])
    @show "test 3 a"
    @variable(sp_m, β[i = V, j = tildeV, k = V′; (i, j, k) in tildeJ] >= 0)
    @variable(sp_m, γ[i = V, j = setdiff(tildeV, i)] >= 0)
    @variable(sp_m, δ[i = V, j = tildeV, k = V′; (i, j, k) in tildeJ] >= 0)
    @variable(sp_m, ζ[i = V, j = V; i != j] >= 0)

    λα = @expression(
        sp_m,
        sum((1 - ŷ[i, i] - sum(ŷ[i, j] for j in setdiff(V, tildeV, i)))α[i] for i in V)
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
        sum((x̂[mima(i, j)] + ŷ[i, j] - ŷ[j, j])ζ[i, j] for i in V, j in setdiff(V, i))
    )


    @objective(sp_m, Max, λα + λβ + λγ + λδ + λζ)

    for i in V
        for j in V′
            if j < n + 1
                if ŷ[i, j] > 0.5
                    @show "ŷ[$i,$j] = $(ŷ[i,j])"
                end
            end
            if i < j
                if x̂[i, j] > 0.5
                    @show "x̂[$i,$j] = $(x̂[i,j])"
                end
            end
        end
    end

    # @show "λα: ", λα
    # @show "λβ: ", λβ
    # @show "λγ: ", λγ
    # @show "λδ: ", λδ
    # @show "λζ: ", λζ


    @show "test 3 b"
    @constraint(
        sp_m,
        x′ik[i = V, k = V; i < k],
        sum(β[i, j, k] - c′[i, k]δ[i, j, k] for j in tildeV if i != j && j != k) - ζ[i, k] -
        ζ[k, i] <= 0
    )

    @constraint(
        sp_m,
        x′it[i = setdiff(V, 1)],
        sum(
            β[(i, j, n + 1)] - c′[i, n+1]δ[(i, j, n + 1)] for
            j in tildeV if i != j && j != n + 1
        ) <= 0
    )

    @show "test 3 b.1"
    @constraint(sp_m, B, sum(δ[i, j, k] for (i, j, k) in tildeJ) <= inst.F)

    @show "test 3 b.2"
    @constraint(
        sp_m,
        y′ij[i = V, j = tildeV; i != j],
        α[i] - d′[i, j]sum(γ[i, k] for k in setdiff(tildeV, i, j)) - ζ[i, j] <= 0
    )
    # @constraint(sp_m, y′ij[i=V, j=setdiff(V,tildeV) ; i != j], α[i] - sum(d′[i,k]γ[i,k] for k in setdiff(tildeV, i, j)) - ζ[i,j] <= 0)

    @show "test 3 b.3"
    # @constraint(sp_m, y′ij_bis[i=V, j=setdiff(V,tildeV, i)], α[i] - sum(d′[i,k]γ[i,k] for k in setdiff(V, tildeV, i, j)) - ζ[i,j] <= 0)

    @show "test 3 b.4"
    @constraint(
        sp_m,
        θ_ij[i = V, j = setdiff(tildeV, i)],
        γ[i, j] - sum(
            δ[(q, j, k)] for
            q in V, k in V′ if q != j && k != j && q < k && !(q == 1 && k == n + 1)
        ) <= 0
    )

    open(eval(@__DIR__) * "/debug/DUAL_$(today()).txt", "w") do io
        write(io, "DUAL MODEL LP\n")
        write(io, "$(all_constraints(sp_m, AffExpr, MOI.LessThan{Float64}))")
    end


    @show "test 3 c"
    optimize!(sp_m)
    @show "test 3 d"




    return objective_value(sp_m), value.(α), value.(β), value.(γ), value.(δ), value.(ζ)
end
