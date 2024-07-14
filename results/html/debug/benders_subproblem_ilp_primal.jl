function sp_optimize_ilp_primal(x̂, ŷ, inst, log_level, gurobi_env)
    n = length(inst.V)
    tildeV = inst.tildeV
    V = inst.V
    V′ = 1:n+1
    d′ = inst.d′
    c′ = inst.c′

    tildeJ = [(i, j, k) for i in V, j in tildeV, k in V′ if i != j && k != j && i < k]

    # gurobi_model = Gurobi.Optimizer(gurobi_env)
    # sp_m = direct_model(gurobi_model)
    sp_m = Model(Gurobi.Optimizer)
    set_optimizer_attribute(sp_m, "OutputFlag", 0)

    log_level <= 1 && set_silent(sp_m)
    @variable(sp_m, x′[i = V, j = V′; i < j] >= 0)
    @variable(sp_m, y′[i = V, j = V; i != j] >= 0)
    @variable(sp_m, θ[i = V, j = tildeV; i != j] >= 0)
    @variable(sp_m, B >= 0)

    @objective(sp_m, Min, inst.F * B)



    @constraint(
        sp_m,
        α[i = V],
        sum(y′[i, j] for j in setdiff(V, i)) ==
        1 - ŷ[i, i] - sum(ŷ[i, j] for j in setdiff(V, tildeV, i))
    )
    @constraint(
        sp_m,
        β_ijk[(i, j, k) = tildeJ],
        x′[mima(i, k)] >= x̂[mima(i, j)] + x̂[mima(j, k)] - 1
    )
    @constraint(
        sp_m,
        γ_ij[i = V, j = setdiff(tildeV, i)],
        θ[i, j] - sum(d′[i, k]y′[i, k] for k in setdiff(V, i, j)) >=
        sum(d′[i, k] * (ŷ[i, j] - 1) for k in setdiff(V, i, j))
    )
    @constraint(
        sp_m,
        δ_ijk[(i, j, k) = tildeJ],
        B - c′[i, k]x′[mima(i, k)] - sum(θ[t, j] for t in setdiff(V, j)) >=
        c′[i, k] * (x̂[mima(i, j)] + x̂[mima(j, k)] - 2)
    )
    @constraint(
        sp_m,
        ζ_ij[i = V, j = V; i != j],
        -x′[mima(i, j)] - y′[i, j] >= -ŷ[j, j] + ŷ[i, j] + x̂[mima(i, j)]
    )



    optimize!(sp_m)

    dual_model = dualize(sp_m; dual_names = DualNames("dual", ""))
    open(eval(@__DIR__) * "/debug/PRIMAL_$(today()).txt", "w") do io
        write(io, "DUAL MODEL Dualization.jl\n")
        write(io, "$(all_constraints(dual_model, AffExpr, MOI.GreaterThan{Float64}))")
    end


    return objective_value(sp_m), Bool.(round.(value.(x′))), Bool.(round.(value.(y′)))
end
