function three(n, o, r, s, tildeV)
    currentobjval = .0
    starcost = .0
    bestobjval = Inf
    bestsol = zeros(Int,4)
    for v1 in 2:n-1
    	if !(v1 in tildeV)
    		for v2 in v1+1:n
    			if !(v2 in tildeV)
    				currentobjval = o[1] + o[v1] + o[v2] + r[1,v1] + r[1,v2] + r[v1,v2]
    				for v in 2:n
    					if v != v1 && v != v2
    						starcost = s[v,1]
    						if s[v,v1] < starcost
    							starcost = s[v,v1]
                            end
    						if s[v,v2] < starcost
    							starcost = s[v,v2]
                            end
    						currentobjval += starcost
    					end
    				end
    				if currentobjval < bestobjval
    					bestobjval = currentobjval
    					bestsol[1] = 1
                        bestsol[2] = v1
                        bestsol[3] = v2
                        bestsol[4] = -1
    				end
    			end
    		end
    	end
    end
    return bestsol, bestobjval
end

function four(n, o, r, s, tildeV, bestobjval, bestsol)
    currentobjval = 0.0
    costcertain = 0.0
    costuncertain = [0.0, 0.0]
    H = [1, 1, 1, 1]
    sol1, sol2, sol3, minsol = .0, .0, .0, .0
    for v1 in 2:n-2
    	for v2 in v1+1:n-1
    		for v3 in v2+1:n
    			currentobjval = o[1] + o[v1] + o[v2] + o[v3]
    			H[2] = v1; H[3] = v2; H[4] = v3
    			for v in 2:n
    				if v != v1 && v != v2 && v != v3
    					costcertain = Inf
    					costuncertain[1] = Inf; costuncertain[2] = Inf
    					for h in 1:4
    						if !(H[h] in tildeV) && s[v,H[h]] < costcertain
    							costcertain = s[v,H[h]]
    						elseif H[h] in tildeV
    							if s[v,H[h]] < costuncertain[1]
    								costuncertain[2] = costuncertain[1]
    								costuncertain[1] = s[v,H[h]]
    							elseif s[v,H[h]] < costuncertain[2]
    								costuncertain[2] = s[v,H[h]]
                                end
    						end
                        end
        				if costcertain <= costuncertain[1] + costuncertain[2]
        					currentobjval += costcertain
        				else
        					currentobjval += costuncertain[1] + costuncertain[2]
        				end
                    end
    			end

                minsol = return_best_ring(v1, v2, v3, r, tildeV, n)[1]

    			if currentobjval + minsol < bestobjval
    				bestobjval = currentobjval + minsol

    				bestsol[1] = 1; bestsol[2] = v1; bestsol[3] = v2; bestsol[4] = v3
    			end
    		end
    	end
    end
    return bestsol, bestobjval
end

function return_best_ring(v1, v2, v3, r, tildeV, n)
    x_opt = zeros(Bool, n, n)
    sol1 = r[1,v1] + r[v1,v2] + r[v2,v3] + r[1,v3]
    x_opt[1,v1] = true
    x_opt[v1, v2] = true
    x_opt[v2, v3] = true
    x_opt[1, v3] = true
    if v1 in tildeV || v3 in tildeV
        sol1 += r[1,v2]
    end
    if 1 in tildeV || v2 in tildeV
        sol1 += r[v1,v3]
    end

    sol2 = r[1,v1] + r[v1,v3] + r[v2,v3] + r[1,v2]
    if v1 in tildeV || v2 in tildeV
        sol2 += r[1,v3]
    end
    if 1 in tildeV || v3 in tildeV
        sol2 += r[v1,v2]
    end

    sol3 = r[1,v2] + r[v1,v2] + r[v1,v3] + r[1,v3]
    if v2 in tildeV || v3 in tildeV
        sol3 += r[1,v1]
    end
    if 1 in tildeV || v1 in tildeV
        sol3 += r[v2,v3]
    end

    minsol = sol1

    if sol2 < sol1 && sol2 < sol3
        x_opt[v1, v2] = false
        x_opt[1, v3] = false
        x_opt[1,v1] = true
        x_opt[v1, v3] = true
        x_opt[v2, v3] = true
        x_opt[1, v2] = true
        minsol = sol2

    elseif sol3 < sol1 && sol3 < sol2
        x_opt[1,v1] = false
        x_opt[v2,v3] = false
        x_opt[1,v2] = true
        x_opt[v1, v2] = true
        x_opt[v1, v3] = true
        x_opt[1, v3] = true
        minsol = sol3
    end

    return minsol, x_opt
end
