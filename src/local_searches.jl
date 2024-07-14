function run_two_opt_wiki(x_opt, x′, hubs, previous_cost, pars, n, r, rp, tildeV)
    number_moves = 0
    pars.two_opt == 1 && @info "Starting 2-opt LocalSearch at $previous_cost"
    improving = true
    improved_x_opt = copy(x_opt)
    improved_x′ = copy(x′)
    R = copy(hubs)
    improved_cost = previous_cost

    h = length(hubs)
    while improving
        improving = false
        for i = 1:h
            for counter = 1:h-3
                j = i + 2
                if j > h
                    j -= h
                end
                # Move i - j
                i_prev = i - 1
                if i_prev < 1
                    i_prev = h
                end
                i_next = i + 1
                if i_next > h
                    i_next = 1
                end
                j_next = j + 1
                if j_next > h
                    j_next = 1
                end
                j_prev = j - 1
                if j_prev < 1
                    j_prev = h
                end
                j_nenext = j_next + 1
                if j_nenext > h
                    j_nenext = 1
                end
                i_nenext = i_next + 1
                if i_nenext > h
                    i_nenext = 1
                end
                saving =
                    r[mima(R[i], R[i_next])] + r[mima(R[j], R[j_next])] -
                    (r[mima(R[i], R[j])] + r[mima(R[i_next], R[j_next])])
                if R[i] in tildeV
                    saving += rp[mima(R[i_prev], R[i_next])] - rp[mima(R[i_prev], R[j])]
                end
                if R[i_next] in tildeV
                    saving += rp[mima(R[i], R[i_nenext])] - rp[mima(R[i_nenext], R[j_next])]
                end
                if R[j] in tildeV
                    saving += rp[mima(R[j_prev], R[j_next])] - rp[mima(R[i], R[j_prev])]
                end
                if R[j_next] in tildeV
                    saving += rp[mima(R[j], R[j_nenext])] - rp[mima(R[i_next], R[j_nenext])]
                end

                if saving > 0 # Move i-j accepted
                    number_moves += 1

                    improved_cost -= saving

                    pars.assert && @assert improved_x_opt[mima(R[i], R[i_next])...]
                    improved_x_opt[mima(R[i], R[i_next])...] = false
                    pars.assert && @assert improved_x_opt[mima(R[j], R[j_next])...]
                    improved_x_opt[mima(R[j], R[j_next])...] = false
                    # @assert improved_x′[mima(R[i_prev], R[i_next])...]
                    improved_x′[mima(R[i_prev], R[i_next])...] = false
                    # @assert improved_x′[mima(R[i], R[i_nenext])...]
                    improved_x′[mima(R[i], R[i_nenext])...] = false
                    # @assert improved_x′[mima(R[j_prev], R[j_next])...]
                    improved_x′[mima(R[j_prev], R[j_next])...] = false
                    # @assert improved_x′[mima(R[j], R[j_nenext])...]
                    improved_x′[mima(R[j], R[j_nenext])...] = false


                    improved_x_opt[mima(R[i], R[j])...] = true
                    improved_x_opt[mima(R[i_next], R[j_next])...] = true

                    improved_x′[mima(R[i_prev], R[j])...] = true * (R[i] in tildeV)
                    improved_x′[mima(R[i_nenext], R[j_next])...] =
                        true * (R[i_next] in tildeV)
                    improved_x′[mima(R[i], R[j_prev])...] = true * (R[j] in tildeV)
                    improved_x′[mima(R[i_next], R[j_nenext])...] =
                        true * (R[j_next] in tildeV)


                    nb_swap = 0
                    if j > i + 1
                        nb_swap = j - i
                    else
                        nb_swap = h - i + 1 + j
                    end
                    start_swap = i_next
                    end_swap = j
                    # @show div(nb_swap, 2), nb_swap
                    for _ = 1:div(nb_swap, 2)
                        R[start_swap], R[end_swap] = R[end_swap], R[start_swap]
                        start_swap += 1
                        if start_swap > h
                            start_swap = 1
                        end
                        end_swap -= 1
                        if end_swap < 1
                            end_swap = h
                        end
                    end

                    improving = true
                    # @goto escape_label
                end

                j += 1
                if j > h
                    j = 1
                end
            end
        end
        # @label escape_label
    end

    pars.assert && @assert improved_cost <= previous_cost
    pars.two_opt == 1 &&
        @info "Finished 2-opt LocalSearch at $improved_cost <= $previous_cost with $(number_moves) moves"
    return improved_x_opt, improved_x′, improved_cost
end
