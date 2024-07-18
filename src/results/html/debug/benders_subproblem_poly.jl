function sp_optimize_poly(x̂, ŷ, inst)
    V = inst.V
    n = length(V)

    tildeV = inst.tildeV
    c′ = inst.c′
    d′ = inst.d′
    n = inst.n
    F = inst.F


    β = Dict{Tuple{Int,Int,Int},Float64}()
    δ = Dict{Tuple{Int,Int,Int},Float64}()
    γ = Dict{Tuple{Int,Int},Float64}()
    ζ = Dict{Tuple{Int,Int},Float64}()
    α = Dict{Int,Float64}()

    i★, j★, k★ = compute_B_critical_triple(inst, x̂, ŷ)[2:4]
    for i in V
        for j in tildeV
            for k = i+1:n+1
                if j != i && j != k
                    if (i, j, k) != (i★, j★, k★)
                        β[i, j, k] = 0
                        δ[i, j, k] = 0
                    end
                end
            end
        end
        if i != j★ && ŷ[i, j★]
            γ[i, j★] = F
            α[i] = F * minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k])
        elseif !ŷ[i, j★]
            γ[i, j★] = 0
        end

        if i != j★ && !ŷ[i, j★]
            α[i] = 0
        end

        for j in setdiff(V, tildeV, i)
            ζ[i, j] = F * minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k]) * ŷ[i, j★]
        end

        for j in setdiff(tildeV, i, j★)
            ζ[i, j] = 0
        end
        ζ[i, j★] = 0 # TODO tell André this is not in the LaTeX document
    end



    for j in setdiff(tildeV, j★)
        for i in setdiff(V, j)
            γ[i, j] = 0
        end
    end
    α[j★] = 0

    β[i★, j★, k★] = F * c′[i★, k★]
    δ[i★, j★, k★] = F

    obj =
        c′[i★, k★] + sum(
            minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k]) for
            i in setdiff(V, j★) if ŷ[i, j★];
            init = 0,
        )

    return obj, α, β, γ, δ, ζ
end

function debug_RRSP(inst, α, α_poly, β, β_poly, γ, γ_poly, δ, δ_poly, ζ, ζ_poly)
    println("test")
    V = inst.V
    n = length(V)
    tildeV = inst.tildeV
    for i in V
        if α[i] > 0 || α_poly[i] > 0
            println("α[$i] = $(α[i]), α_poly[$i] = $(α_poly[i])")
        end
    end
    for i in V
        for j in tildeV
            for k = i+1:n+1
                if i != j && j != k
                    if β[i, j, k] > 0 || β_poly[i, j, k] > 0
                        println(
                            "β[$i, $j, $k] = $(β[i,j,k]), β_poly[$i, $j, $k] = $(β_poly[i,j,k])",
                        )
                    end
                end
            end
        end
    end
    for i in V
        for j in setdiff(tildeV, i)
            if γ[i, j] > 0 || γ_poly[i, j] > 0
                println("γ[$i, $j] = $(γ[i,j]), γ_poly[$i,$j] = $(γ_poly[i,j])")
            end
        end
    end
    for i in V
        for j in tildeV
            for k = i+1:n+1
                if i != j && j != k
                    if δ[i, j, k] > 0 || δ_poly[i, j, k] > 0 && !(i == 1 && k == n + 1)
                        println(
                            "δ[$i, $j, $k] = $(δ[i,j,k]), δ_poly[$i, $j, $k] = $(δ_poly[i,j,k]) cost[$(inst.d′[i,k == n+1 ? 1 : k])]",
                        )
                    end
                end
            end
        end
    end
    for i in V
        for j in setdiff(V, i)
            if ζ[i, j] > 0 || ζ_poly[i, j] > 0
                println("ζ[$i, $j] = $(ζ[i,j]), ζ_poly[$i,$j] = $(ζ_poly[i,j])")
            end
        end
    end
end

function compute_sims(i, ŷ, s, V, tildeV)
    sim_i = Inf
    m_i = 0
    for j in tildeV
        if j != i && ŷ[j] && sim_i > s[i, j]
            sim_i = s[i, j]
            m_i = j
        end
    end
    sim_i′ = Inf
    m_i′ = 0

    for j in tildeV
        if j != i && j != m_i && ŷ[j]
            if sim_i′ > s[i, j]
                sim_i′ = s[i, j]
                m_i′ = j
            end
        end
    end
    sim_istar = Inf
    m_istar = 0

    for j in V
        if j != i && j in setdiff(V, tildeV) && ŷ[j]
            if sim_istar > s[i, j]
                sim_istar = s[i, j]
                m_istar = j
            end
        end
    end
    return sim_i, m_i, sim_i′, m_i′, sim_istar, m_istar
end
